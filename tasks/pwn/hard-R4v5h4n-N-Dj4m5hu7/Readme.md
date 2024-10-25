# pwn | R4v5h4n N Dj4m5hu7

## Information

Во время своей работы, системным администраторам довольно часто приходится производить поиск по логам. Хакеры из бара *название бара*, занимающиеся администрированием сетевой инфраструктуры не исключение. Однако современные решения для фильтрации файлов, по типу grep, их не устраивают, а времени и желания разрабатывать своё у них нет. Поэтому было принято решение обратиться к мастодононтам компьютерного взлома - хакерам R4v5h4n и Dj4m5hu7. Месяц спустя работа была готова, но хакеры настояли на личной встрече для демонстрации своей разработки и передачи оплаты. Делать было нечего - аванс был уже выплачен, нанимать других людей было бы слишком затратно, пришлось согласиться. Жребий идти на встречу выпал мне. Мне назвали адрес дома, спустя минут 30 я был уже на месте. Дом этот был весьма странным, весь кривой, облицованный плиткой разного размера и цвета, а ещё батареи для отопления почему-то висели снаружи. Но это были ещё цветочки, то что я увидел внутри повергло меня в шок...

During their work, system administrators often have to search through logs. The hackers from the bar *bar name*, who are involved in managing network infrastructure, are no exception. However, they are not satisfied with modern file filtering solutions like grep, and they don’t have the time or desire to develop their own. Therefore, a decision was made to turn to the veterans of computer hacking - hackers R4v5h4n and Dj4m5hu7. A month later, the work was ready, but the hackers insisted on a personal meeting to demonstrate their development and receive payment. There was nothing I could do - the advance had already been paid, hiring other people would be too expensive, so I had to agree. The lot fell on me to go to the meeting. I was given the address of the house, and about 30 minutes later, I arrived at the location. The house was quite strange, all crooked, clad in tiles of different sizes and colors, and for some reason, the heating batteries were hanging outside. But that was just the beginning; what I saw inside left me in shock...

## Deploy

```sh
cd deploy
docker compose -p r4v5h4n up --build -d
```

## Public

Provide zip archive: [public/R4v5h4n.zip](public/R4v5h4n.zip).

## TLDR

The task involves modifying a file without accompanying privileges by passing a file descriptor from a more privileged process, resulting from altering the msghdr structure through a buffer overflow.

## Writeup (ru)

В данном задании участникам давался SSH доступ  на удалённый сервер. Подключившись к нему, необходимо было обнаружить файлы: */home/task/server* и */home/ssh_user/client*, представляющие из себя сервер и клиент, соответственно. Сервер предоставлял примитивный аналог утилиты *grep*, реализующий поиск в файлах строк, содержащих заданную пользователем последовательность символов и исполнялся от лица привилегированного пользователя, имеющего права на чтение файла с флагом. Отправка сервером результатов работы происходила через *AF_UNIX* сокет, посредством функции *sendmsg*. Помимо этого, сервер открывал два файла - первый содержал список файлов, запрещённых на чтение, а второй содержал путь до файла с флагом.  Сервер не позволял прочесть файл с флагом, поскольку сравнивал путь, полученный из данного файла, с путём до файла, указанного пользователем.

Сервер содержал в себе несколько уязвимостей. Первая предоставляла возможность прочтения файлов в обход чёрного списка. В начале своей работы программа построчно считывала файл, содержащий имена запрещённых файлов и получала их *inode*-идентификаторы. Далее они сравнивались идентификаторами файлов, которые указал пользователь. Серверу можно было указать, как файл, так и директорию, в первом случае  *inode*-идентификатор вычислялся, с помощью функции *stat*, во втором использовался идентификатор, который вернула функция *readdir*. В случае, если в директории содержится символьная ссылка, *readdir* вернёт идентификатор ссылки, а не файла на который она указывает. Таким образом, создав временную директорию, добавив туда символьную ссылку на запрещённый файл и указав серверу путь до директории, можно заставить сервер прочесть файл из чёрного списка, на который указывает символьная ссылка.

Вторая уязвимость представляет собой *integer-overflow*, ведущее к переполнению буфера. При получении пути до файла/директории и подстроки для поиска, сервер для начала считывает из сокета 4 байта в переменную типа *signed int*, после чего проверяет, превосходит ли получившееся число размер буфера и в случае если не превосходит, считывает соответствующее количество байт в буфер. Однако в случае передачи клиентом отрицательного числа проверка размера будет успешно пройдена, при этом в буфер считается большее количество байт, поскольку функция recv принимает беззнаковое число. В связи с этим, появляется возможность изменить структуру *msghdr*, передающуюся функции *sendmsg*, для отправки клиенту найденных строк.

В ОС Linux существует возможность, с помощью сокетов типа *AF_UNIX*, передать другому процессу файловый дескриптор. При этом, в результате такой передачи, менее привилегированный процесс может осуществлять чтение и запись в файловый дескриптор, указывающий на файл, для которого у него нет прав на чтение и запись. А значит, что переполнив буфер и изменив структуру *msghdr*, можно передать клиенту произвольный файловый дескриптор, открытый программой-сервером.

Конечный сценарий эксплуатации выглядит следующим образом:
1. Обойдя проверку, прочитать располагающийся в чёрном списке файл */proc/self/maps*.
2. С помощью переполнения буфера, изменить структуру *msghdr*. Данная структура содержит в себе указатель на другую структуру - *cmsghdr*, непосредственно содержащую идентификатор передаваемого  дескриптора. Именно поэтому, вначале необходимо было прочитать */proc/self/maps* - чтобы посчитать корректный адрес. Нужный дескриптор должен указывать на ранее упомянутый, файл содержащий путь до флага. Поскольку данный файл открывается на чтение и запись, а также полученный дескриптор, после прочтения файла, не закрывается, передача его с целью модификации конечного файла представляется возможной.
3. На клиентской стороне принять файловый дескриптор и записать в файл некорректный путь.
4. Прочесть файл с флагом, используя функционал сервера.

Исходный код, реализующий вышеописанный процесс, за исключением последнего шага (его необходимо производить, через размещённый на сервере клиент), реализован в эксплойте *exp.c*.

## Writeup (en)

In this task, participants were given SSH access to a remote server. After connecting to it, they needed to find the files: */home/task/server* and */home/ssh_user/client*, which represented the server and client, respectively. The server provided a primitive analog of the *grep* utility, implementing a search in files for lines containing a user-specified sequence of characters and was executed by a privileged user who had read permissions for the flag file. The server sent the results through an *AF_UNIX* socket using the *sendmsg* function. Additionally, the server opened two files: the first contained a list of files that were prohibited from being read, and the second contained the path to the flag file. The server did not allow reading the flag file, as it compared the path obtained from this file with the path to the file specified by the user.

The server contained several vulnerabilities. The first allowed reading files bypassing the blacklist. At the start of its operation, the program read line by line the file containing the names of prohibited files and obtained their *inode* identifiers. These were then compared with the identifiers of the files specified by the user. The server could be provided with either a file or a directory; in the first case, the *inode* identifier was computed using the *stat* function, while in the second case, the identifier returned by the *readdir* function was used. If a symbolic link exists in the directory, *readdir* would return the identifier of the link, not the file it points to. Thus, by creating a temporary directory, adding a symbolic link to a prohibited file there, and providing the server with the path to the directory, one could force the server to read the blacklisted file that the symbolic link points to.

The second vulnerability is an *integer overflow* leading to a buffer overflow. When receiving the path to a file/directory and the substring to search for, the server first reads 4 bytes from the socket into a variable of type *signed int*, then checks if the resulting number exceeds the size of the buffer. If it does not exceed, it reads the corresponding number of bytes into the buffer. However, if the client sends a negative number, the size check will pass successfully, and a larger number of bytes will be read into the buffer since the *recv* function accepts an unsigned number. As a result, there is an opportunity to modify the *msghdr* structure passed to the *sendmsg* function to send the found strings to the client.

In Linux, it is possible to use *AF_UNIX* sockets to pass a file descriptor to another process. As a result of such transmission, a less privileged process can read from and write to a file descriptor pointing to a file for which it does not have read and write permissions. Therefore, by overflowing the buffer and modifying the *msghdr* structure, it is possible to send the client an arbitrary file descriptor opened by the server program.

The final exploitation scenario looks as follows:
1. Bypass the check to read the file */proc/self/maps*, which is on the blacklist.
2. Use the buffer overflow to modify the *msghdr* structure. This structure contains a pointer to another structure - *cmsghdr*, which directly contains the identifier of the passed descriptor. That is why it was necessary to read */proc/self/maps* first - to calculate the correct address. The required descriptor should point to the previously mentioned file containing the path to the flag. Since this file is opened for reading and writing, and the obtained descriptor is not closed after reading the file, passing it for the purpose of modifying the final file is feasible.
3. On the client side, accept the file descriptor and write an incorrect path to the file.
4. Read the flag file using the server's functionality.

The source code implementing the above process, except for the last step (which needs to be performed using the client hosted on the server), is implemented in the exploit *exp.c*.


[Exploit](solve/exp.c)


## Cloudflare

No
