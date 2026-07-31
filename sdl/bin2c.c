/* Build-time helper (see build_shim.sh): dumps a file's bytes as a C byte
 * array + length, so a font can be compiled directly into the binary
 * instead of loaded from a runtime path. Spinel's __dir__ resolves to a
 * compile-time literal of the source tree (the machine that ran `spin
 * build`), not the running executable's location -- so any path built
 * from it only resolves on that same machine. Embedding sidesteps the
 * problem entirely: no path, no dependency on where the binary ends up.
 */
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: bin2c <input-file> <symbol-name>\n");
        return 1;
    }

    FILE *in = fopen(argv[1], "rb");
    if (!in) {
        perror(argv[1]);
        return 1;
    }

    printf("const unsigned char %s[] = {\n", argv[2]);

    unsigned int count = 0;
    int col = 0;
    int c;
    while ((c = fgetc(in)) != EOF) {
        printf("%d,", c);
        count++;
        col++;
        if (col == 20) {
            printf("\n");
            col = 0;
        }
    }
    fclose(in);

    printf("\n};\n");
    printf("const unsigned int %s_len = %uu;\n", argv[2], count);
    return 0;
}
