#include <stdio.h>
#include <stdlib.h>

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stdin, NULL, _IONBF, 0);
  char delim[128];
  printf("delim> ");
  fgets(delim, 128, stdin);

  int n_columns;
  int n_rows;

  printf("columns> ");
  scanf("%i", &n_columns);
  printf("rows> ");
  scanf("%i", &n_rows);

  char ***table = malloc(n_rows * sizeof(char **));
  if (table == NULL) {
    exit(1);
  }

  char *scan_fmt;
  asprintf(&scan_fmt, "%%m[^n]%s%%n", delim);
  char *line = NULL;
  size_t line_size = 0;
  getline(&line, &line_size, stdin);
  free(line);

  for (int i = 0; i < n_rows; i++) {
    table[i] = malloc(n_columns * sizeof(char *));
    if (table[i] == NULL) {
      exit(1);
    }
    char *line = NULL;
    size_t line_size = 0;
    int line_offset;
    getline(&line, &line_size, stdin);
    for (int j = 0; j < n_columns && line_offset < line_size; j++) {
      int read;
      /*printf("%19$p\n");*/
      sscanf(line + line_offset, scan_fmt, &table[i][j], &read);
      line_size += read;
    }
    free(line);
  }
}
