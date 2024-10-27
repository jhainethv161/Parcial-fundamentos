section .data
    mensaje_num db 'Ingrese dos números enteros separados por un espacio: ', 0xA, 0  ; Mensaje para solicitar números
    mensaje_op db 'Ingrese la operación (+, -, *, /) o "exit" para salir: ', 0xA, 0  ; Mensaje para solicitar operación
    resultado db 'Resultado: ', 0xA, 0  ; Mensaje para mostrar el resultado
    error_division db 'Error: División por cero.', 0xA, 0  ; Mensaje de error para división por cero
    error_op db 'Error: Operación no válida.', 0xA, 0  ; Mensaje de error para operación inválida
    salir db 'exit', 0  ; Cadena para salir del programa

section .bss
    buffer resb 128               ; Espacio para la entrada
    num1 resd 1                   ; Espacio para el primer numero
    num2 resd 1                   ; Espacio para el segundo numero
    res resd 1                    ; Espacio para el resultado
    operacion resb 1              ; Espacio para la operacion
    temp resb 16                  ; Espacio para almacenar el resultado en codigo ASCII

section .text
    global _start                 ; Punto de partida del programa

_start:
ciclo:
                                  ; Solicitar numeros al usuario
    mov eax, 4                    ; Llamada al sistema tipo: write
    mov ebx, 1                    ; Archivo descriptor: stdout (Muestra informacion)
    mov ecx, mensaje_num          ; Mostrar mensaje
    mov edx, 54                   ; Longitud del mensaje
    int 0x80                      ; Llamada al sistema

                                  ; Leer la informacion ingresada por el usuario
    mov eax, 3                    ; Llamada al sistem tipo: read
    mov ebx, 0                    ; Archivo descriptor: stdin (Solicita informacion)
    mov ecx, buffer               ; Donde se guardara la entrada
    mov edx, 128                  ; Tamaño maximo a leer
    int 0x80                      ; Llamada al sistema

    call ascii_a_entero           ; Llamar la funcion para convertir entrada ASCII a enteros

                                  ; Solicitar la operacion al usuario
    mov eax, 4
    mov ebx, 1
    mov ecx, mensaje_op
    mov edx, 56
    int 0x80

                                  ; Leer la operacion
    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 128
    int 0x80

                                  ; Comparar con "exit"
    mov ecx, buffer
    mov esi, salir
    call comparar_cadena
    cmp eax, 0
    je salir_programa             ; Si se quiere salir, ir al metodo de salida

                                  ; Guardar la operacion en variable 'operacion'
    movzx eax, byte [buffer]      ; Obtener el primer caracter de la operacion
    mov [operacion], eax          ; Almacenar operacion

                                  ; Determinar la operacion a ejecutar
    cmp byte [operacion], '+'
    je suma
    cmp byte [operacion], '-'
    je resta
    cmp byte [operacion], '*'
    je multiplicacion
    cmp byte [operacion], '/'
    je division

                                  ; Error: Operacion no valida
    mov eax, 4
    mov ebx, 1
    mov ecx, error_op
    mov edx, 28
    int 0x80
    jmp ciclo                    ; Volver a solicitar

suma:
    mov eax, [num1]              ; Guardar el primer numero
    add eax, [num2]              ; Sumar el segundo numero
    mov [res], eax               ; Guardar el resultado
    jmp mostrar_resultado        ; Mostrar el resultado

resta:
    mov eax, [num1]
    sub eax, [num2]
    mov [res], eax
    jmp mostrar_resultado

multiplicacion:
    mov eax, [num1]
    imul eax, [num2]             ; Multiplicar
    mov [res], eax
    jmp mostrar_resultado

division:
    mov eax, [num2]             ; Guardar el segundo numero
    cmp eax, 0                  ; Comprobar si es cero
    je error_div                ; Si es cero, muestra error de division

    mov eax, [num1]             ; Guardar el primer numero
    cdq                         ; Extender el signo en edx:eax para la division
    idiv dword [num2]           ; Dividir edx:eax entre num2,en eax

    mov [res], eax              ; Guardar el resultado en res
    jmp mostrar_resultado       ; Mostrar el resultado

error_div:
    mov eax, 4
    mov ebx, 1
    mov ecx, error_division
    mov edx, 27
    int 0x80
    jmp ciclo                   ; Regresar al ciclo

mostrar_resultado:
    mov eax, [res]              ; Guardar el resultado
    call entero_a_ascii         ; Convertir el entero a codigo ASCII

                                ; Mostrar el resultado
    mov eax, 4
    mov ebx, 1
    mov ecx, resultado
    mov edx, 12
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, temp               ; Mostrar el resultado en codigo ASCII
    mov edx, 16
    int 0x80

    jmp ciclo                   ; Regresar al ciclo

salir_programa:
    mov eax, 1                  ; Llamada al sistema: exit
    xor ebx, ebx                ; codigo de salida 0
    int 0x80
ascii_a_entero:
    mov esi, buffer             ; Apuntar al buffer (Region de memoria para almacenar datos temporalmente)
    call extraer_entero         ; Extraer el primer numero entero
    mov [num1], eax             ; Almacenar en variable num1

    call extraer_entero         ; Extraer el segundo numero entero
    mov [num2], eax             ; Almacenar en variable num2
    ret

extraer_entero:
    xor eax, eax                ; Limpiar eax para el numero entero
    mov bl, [esi]               ; Guardar el valor actual
    cmp bl, '-'                 ; Verificar si es negativo
    je negativo                 ; Si es negativo, controlarlo
    cmp bl, '0'
    jb fin_convertir            ; Si no es un digito, terminar
    cmp bl, '9'
    ja fin_convertir            ; Si no es un digito, terminar
    sub bl, '0'                 ; Convertir de codigo ASCII a numero
    jmp convertir

negativo:
    inc esi                     ; Moverse al siguiente caracter
    jmp convertir_negativo

convertir_negativo:
    mov bl, [esi]
    cmp bl, '0'
    jb fin_convertir
    cmp bl, '9'
    ja fin_convertir
    sub bl, '0'
    imul eax, eax, 10
    add eax, ebx
    inc esi
    jmp convertir_negativo

convertir:
    mov bl, [esi]
    cmp bl, '0'
    jb fin_convertir
    cmp bl, '9'
    ja fin_convertir
    sub bl, '0'
    imul eax, eax, 10
    add eax, ebx
    inc esi
    jmp convertir

fin_convertir:
    inc esi                     ; Moverse al siguiente caracter
    ret

comparar_cadena:
    xor eax, eax                ; Limpiar eax para el resultado
comparar_loop:
    mov al, [ecx]               ; Cargar el caracter de buffer (Memoria temporal reservada)
    cmp al, [esi]               ; Comparar con el caracter de 'exit'
    jne cadenas_diferentes

    test al, al
    je cadenas_iguales          ; Si es vacio,son iguales

    inc ecx                     ; Continuar en la cadena de entrada
    inc esi                     ; Continuar en la cadena de comparacion
    jmp comparar_loop           ; Continuar comparando

cadenas_diferentes:
    mov eax, 1                  ; Son diferentes las cadenas
    ret

cadenas_iguales:
    xor eax, eax                ; Son iguales las cadenas
    ret

entero_a_ascii:
    mov edi, temp               ; Direccionar donde se almacenara el numero
    mov ecx, 10                 ; Divisor para obtener decimales
    xor ebx, ebx                ; Registro temporal para almacenar informacion

convertir_loop:
    xor edx, edx                ; Limpiar edx antes de la division
    div ecx                     ; Dividir eax entre 10
    add dl, '0'                 ; Convertir el residuo en caracter de codigo ASCII
    mov [edi], dl               ; Guardar el caracter en variable temp
    inc edi                     ; Continuar al siguiente espacio en temp
    test eax, eax               ; Comprobar si ya se han convertido todos los dígitos
    jnz convertir_loop          ; Si eax no es 0, continuar convirtiendo

                                ; Revertir la cadena en temp
    mov esi, temp               ; Direccionar a la primera posicion de temp
    dec edi                     ; Retroceder a la ultima posicion ocupada

revertir_loop:
    cmp esi, edi                ; Comparar los indices
    jge fin_revertir            ; Si se cruzan, terminar
    mov al, [esi]               ; Guardar caracter en al
    mov bl, [edi]               ; Guardar caracter en bl
    mov [esi], bl               ; Intercambiar
    mov [edi], al               ; Intercambiar
    inc esi                     ; Avanzar desde el principio
    dec edi                     ; Retroceder desde el final
    jmp revertir_loop

fin_revertir:
    ret                         ; Volver a la funcion