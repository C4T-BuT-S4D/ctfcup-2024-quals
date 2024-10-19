
SECTIONS
{
    . = 0x1000; /* Начало сегмента */
    my_section : {
        KEEP(*(.my_section))
    }
}
