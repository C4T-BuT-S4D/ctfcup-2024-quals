package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path"
	"time"
	"unicode"

	"github.com/golang-jwt/jwt/v5"
	etcd "go.etcd.io/etcd/client/v3"
)

const (
	etcdUserNs = "user"
	etcdDataNs = "data"
)

type EtcdStore struct {
	opTimeout time.Duration
	client    *etcd.Client
}

type User struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func env(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func etcdKey(parts ...string) string {
	return "/" + path.Join(parts...)
}

func (store *EtcdStore) AddUser(ctx context.Context, user User) error {
	ctx, cancel := context.WithTimeout(ctx, store.opTimeout)
	defer cancel()

	_, err := store.client.Put(ctx, etcdKey(etcdUserNs, user.Username, "password"), user.Password)
	if err != nil {
		return fmt.Errorf("failed to store user: %v", err)
	}

	return nil
}

func (store *EtcdStore) GetUser(ctx context.Context, username string) (User, error) {
	ctx, cancel := context.WithTimeout(ctx, store.opTimeout)
	defer cancel()

	resp, err := store.client.Get(ctx, etcdKey(etcdUserNs, username, "password"))
	if err != nil {
		return User{}, fmt.Errorf("failed to get user: %v", err)
	}

	if len(resp.Kvs) == 0 {
		return User{}, fmt.Errorf("user not found")
	}

	return User{
		Username: username,
		Password: string(resp.Kvs[0].Value),
	}, nil
}

func (store *EtcdStore) StoreKey(ctx context.Context, user string, key string, value string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, store.opTimeout)
	defer cancel()

	storeKey := etcdKey(etcdUserNs, user, etcdDataNs, key)
	_, err := store.client.Put(ctx, storeKey, value)
	if err != nil {
		return "", fmt.Errorf("failed to store key: %v", err)
	}

	return storeKey, nil
}

func (store *EtcdStore) GetKey(ctx context.Context, user string, key string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, store.opTimeout)
	defer cancel()

	resp, err := store.client.Get(ctx, etcdKey(etcdUserNs, user, etcdDataNs, key))
	if err != nil {
		return "", fmt.Errorf("failed to get key: %v", err)
	}

	if len(resp.Kvs) == 0 {
		return "", fmt.Errorf("key not found")
	}

	return string(resp.Kvs[0].Value), nil
}

func (store *EtcdStore) ListKeys(ctx context.Context, user string) ([]string, error) {
	ctx, cancel := context.WithTimeout(ctx, store.opTimeout)
	defer cancel()

	userKey := etcdKey(etcdUserNs, user, etcdDataNs)
	resp, err := store.client.Get(ctx, userKey, etcd.WithPrefix())
	if err != nil {
		return nil, fmt.Errorf("failed to list keys: %v", err)
	}

	keys := make([]string, 0, len(resp.Kvs))
	for _, kv := range resp.Kvs {
		keys = append(keys, string(kv.Key))
	}

	return keys, nil
}

type StoreHandler struct {
	store *EtcdStore
}

func getJwtSecretKey() []byte {
	return []byte(env("JWT_SECRET", "secret"))
}

func getUserFromToken(token string) (string, error) {
	tok, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		return getJwtSecretKey(), nil
	}, jwt.WithValidMethods([]string{"HS256"}))
	if err != nil {
		return "", fmt.Errorf("failed to parse token: %v", err)
	}

	if claims, ok := tok.Claims.(jwt.MapClaims); ok {
		username, ok := claims["username"]
		if !ok {
			return "", fmt.Errorf("username not found in token")
		}
		return username.(string), nil
	}

	return "", fmt.Errorf("invalid token")
}

func createJwtToken(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)
	claims["username"] = username
	claims["exp"] = time.Now().Add(time.Hour * 24).Unix()

	tokenString, err := token.SignedString(getJwtSecretKey())
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %v", err)
	}

	return tokenString, nil
}

func isAlphanumeric(value string) bool {
	for _, char := range value {
		if !unicode.IsLetter(char) && !unicode.IsDigit(char) {
			return false
		}
	}
	return true
}

func (sh *StoreHandler) Register(w http.ResponseWriter, r *http.Request) {
	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if user.Username == "" || user.Password == "" {
		http.Error(w, "missing username or password", http.StatusBadRequest)
		return
	}

	if !isAlphanumeric(user.Username) {
		http.Error(w, "username must be alphanumeric", http.StatusBadRequest)
		return
	}

	if _, err := sh.store.GetUser(context.Background(), user.Username); err == nil {
		http.Error(w, "user already exists", http.StatusConflict)
		return
	}

	if err := sh.store.AddUser(context.Background(), user); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	tok, err := createJwtToken(user.Username)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "%q", tok)
}

func (sh *StoreHandler) Login(w http.ResponseWriter, r *http.Request) {
	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if user.Username == "" || user.Password == "" {
		http.Error(w, "missing username or password", http.StatusBadRequest)
		return
	}

	storedUser, err := sh.store.GetUser(context.Background(), user.Username)
	if err != nil {
		http.Error(w, "invalid username or password", http.StatusUnauthorized)
		return
	}

	if storedUser.Password != user.Password {
		http.Error(w, "invalid username or password", http.StatusUnauthorized)
		return
	}

	tok, err := createJwtToken(user.Username)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%q", tok)
}

func (sh *StoreHandler) Store(w http.ResponseWriter, r *http.Request) {
	user, err := getUserFromToken(r.Header.Get("Authorization"))
	if err != nil {
		log.Printf("failed to get user from token: %v", err)
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var value string
	if err := json.NewDecoder(r.Body).Decode(&value); err != nil {
		http.Error(w, "Missing value", http.StatusBadRequest)
		return
	}

	key := r.PathValue("key")

	if key == "" || value == "" {
		http.Error(w, "missing key or value", http.StatusBadRequest)
		return
	}

	if _, err := sh.store.StoreKey(context.Background(), user, key, value); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func (sh *StoreHandler) Get(w http.ResponseWriter, r *http.Request) {
	user, err := getUserFromToken(r.Header.Get("Authorization"))
	if err != nil {
		log.Printf("failed to get user from token: %v", err)
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	key := r.PathValue("key")
	if key == "" {
		http.Error(w, "missing key", http.StatusBadRequest)
		return
	}

	value, err := sh.store.GetKey(context.Background(), user, key)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "%q", value)
	w.Header().Set("Content-Type", "application/json")
}

func (sh *StoreHandler) List(w http.ResponseWriter, r *http.Request) {
	user, err := getUserFromToken(r.Header.Get("Authorization"))
	if err != nil {
		log.Printf("failed to get user from token: %v", err)
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	keys, err := sh.store.ListKeys(context.Background(), user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(keys); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func initAdmin(store *EtcdStore) {
	admin := User{
		Username: "admin",
		Password: env("ADMIN_PASSWORD", "*REDACTED*"),
	}
	if err := store.AddUser(context.Background(), admin); err != nil {
		log.Fatalf("failed to add admin user: %v", err)
	}

	flagKey := env("FLAG_KEY", "flag")
	flagValue := env("FLAG", "ctfcup{redacted}")
	if _, err := store.StoreKey(context.Background(), admin.Username, flagKey, flagValue); err != nil {
		log.Fatalf("failed to store flag: %v", err)
	}
}

func main() {
	etcdHost := env("ETCD_HOST", "http://localhost:2379")
	client, err := etcd.NewFromURL(etcdHost)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create etcd client: %v\n", err)
		os.Exit(1)
	}

	store := &EtcdStore{
		opTimeout: 10 * time.Second,
		client:    client,
	}

	initAdmin(store)

	handler := &StoreHandler{store: store}

	http.HandleFunc("POST /auth/register", handler.Register)
	http.HandleFunc("POST /auth/login", handler.Login)
	http.HandleFunc("POST /data/{key...}", handler.Store)
	http.HandleFunc("GET /data/{key...}", handler.Get)
	http.HandleFunc("GET /data", handler.List)

	log.Printf("listening on :8080\n")

	http.ListenAndServe(":8080", nil)
}
