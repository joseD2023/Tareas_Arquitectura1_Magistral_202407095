//  datos 
    .section .data

// entradas que se ponen en X0 (las salidas van en 0)
entradas_2:     .word 0x000, 0x489, 0x912, 0xD9B                              // A,B = 00, 01, 10, 11
entradas_3:     .word 0x000, 0x085, 0x508, 0x58D, 0xA10, 0xA95, 0xF18, 0xF9D  // A,B,C = 000 a 111

// salida esperada por combinacion: 1 = salidas en 1, 0 = salidas en 0
esperado_7400:  .word 1, 1, 1, 0                // NAND
esperado_7408:  .word 0, 0, 0, 1                // AND
esperado_7432:  .word 0, 1, 1, 1                // OR
esperado_7427:  .word 1, 0, 0, 0, 0, 0, 0, 0    // NOR de 3 entradas

// bit de salida de cada compuerta (compuerta 1, 2, 3, 4)
bits_salida_2:  .word 0x200, 0x040, 0x020, 0x004    // D9, D6, D5, D2 (7400, 7408, 7432)
bits_salida_3:  .word 0x002, 0x040, 0x020           // D1, D6, D5 (7427)

// Mensajes que se muestran en pantalla
msg_pedir:      .ascii "Ingrese tipo de integrado (00, 08, 27 o 32): "
msg_pedir_fin:

msg_invalido:   .ascii "Tipo incorrecto. Intente de nuevo.\n"
msg_invalido_fin:

msg_ok:         .ascii "Integrado en buen estado: IC OK\n"
msg_ok_fin:

msg_mal:        .ascii "Integrado danado: IC MAL\n"

// El numero 1 se reemplaza por la compuerta que fallo
msg_compuerta:  .ascii "Compuerta 1 danada\n"
msg_compuerta_fin:



        .section .bss
buzon_teclado:  .skip 8                             // utilizacion de la tecla 
        .global _start
        .text

// x6  = entradas            x12 = esperados         x13 = bits de salida
// x9  = total combinaciones x14 = total compuertas
// w10 = mascara de salidas  w11 = fallos acumulados
// x7  = contador (combinacion o compuerta)

_start:
inicio:

// pedir tipo de chip 
        mov   x0, #1                                // 1 = pantalla
        ldr   x1, =msg_pedir
        mov   x2, #(msg_pedir_fin - msg_pedir)      // largo calculado solo
        mov   x8, #64                               // 64 = write
        svc   #0

// leer 2 digitos + enter 
        mov   x0, #0                                // 0 = teclado
        ldr   x1, =buzon_teclado
        mov   x2, #8
        mov   x8, #63                               // 63 = read
        svc   #0                                    // x0 = cuantos caracteres leyo

        cmp   x0, #3                                // deben ser 3: dos digitos y enter
        b.ne  tipo_no_valido

        ldr   x1, =buzon_teclado
        ldrb  w2, [x1]                              // primer digito
        ldrb  w3, [x1, #1]                          // segundo digito
        ldrb  w5, [x1, #2]                          // enter (valor 10)
        cmp   w5, #10
        b.ne  tipo_no_valido

        sub   w2, w2, #48                           // ASCII a numero ('0' = 48)
        sub   w3, w3, #48
        cmp   w2, #9                                // validar que sean digitos
        b.hi  tipo_no_valido
        cmp   w3, #9
        b.hi  tipo_no_valido

        mov   w4, #10
        madd  w4, w2, w4, w3                        // w4 = decenas*10 + unidades

// elegir chip 
        cmp   w4, #0
        b.eq  preparar_7400
        cmp   w4, #8
        b.eq  preparar_7408
        cmp   w4, #27
        b.eq  preparar_7427
        cmp   w4, #32
        b.eq  preparar_7432

tipo_no_valido:
        mov   x0, #1
        ldr   x1, =msg_invalido
        mov   x2, #(msg_invalido_fin - msg_invalido)
        mov   x8, #64
        svc   #0
        b     inicio


// preparar datos del chip 
preparar_7400:
        ldr   x12, =esperado_7400
        b     preparar_2_entradas
preparar_7408:
        ldr   x12, =esperado_7408
        b     preparar_2_entradas
preparar_7432:
        ldr   x12, =esperado_7432
        b     preparar_2_entradas

preparar_2_entradas:                                // los 3 chips de 2 entradas
        ldr   x6, =entradas_2
        ldr   x13, =bits_salida_2
        mov   x9, #4                                // 4 combinaciones
        mov   x14, #4                               // 4 compuertas
        mov   x10, #0x264                           // D9 + D6 + D5 + D2
        b     probar_chip

preparar_7427:
        ldr   x12, =esperado_7427
        ldr   x6, =entradas_3
        ldr   x13, =bits_salida_3
        mov   x9, #8                                // 8 combinaciones
        mov   x14, #3                               // 3 compuertas
        mov   x10, #0x062                           // D6 + D5 + D1


// excitar, esperar 10 ms y revisar 
probar_chip:
        mov   x11, #0                               // sin fallos al inicio
        mov   x7, #0                                // combinacion actual

siguiente_combo:
        cmp   x7, x9
        b.ge  mostrar_resultado                     // ya probe todas

        ldr   w0, [x6, x7, lsl #2]                  // X0 = entradas, el hardware responde

        ldr   x15, =1000000                         // espera 10 ms 
espera_10ms:
        subs  x15, x15, #1
        b.ne  espera_10ms

        and   w3, w0, w10                           // solo los bits de salida
        ldr   w5, [x12, x7, lsl #2]                 // esperado: 0 o 1
        mul   w5, w5, w10                           // 0 = todas en 0, 1 = todas en 1
        eor   w3, w3, w5                            // bits distintos = salida mala
        orr   w11, w11, w3                          // acumular fallos

        add   x7, x7, #1
        b     siguiente_combo


// mostrar resultado 
mostrar_resultado:
        cmp   w11, #0
        b.eq  chip_ok                               // ningun fallo
        cmp   w11, w10
        b.eq  chip_malo                             // fallaron todas las salidas

        mov   x7, #0                                // fallo parcial: ver compuerta por compuerta
revisar_compuerta:
        cmp   x7, x14
        b.ge  inicio

        ldr   w3, [x13, x7, lsl #2]                 // bit de salida de esta compuerta
        tst   w3, w11
        b.eq  compuerta_sana                        // esta compuerta esta bien

        // Obtener el numero de compuerta: 1, 2, 3 o 4
        add   w4, w7, #49
        // Reemplazar el numero del mensaje
        ldr   x1, =msg_compuerta
        strb  w4, [x1, #10]
        mov   x0, #1
        mov   x2, #(msg_compuerta_fin - msg_compuerta)
        mov   x8, #64
        svc   #0

compuerta_sana:
        add   x7, x7, #1
        b     revisar_compuerta

chip_ok:
        mov   x0, #1
        ldr   x1, =msg_ok
        mov   x2, #(msg_ok_fin - msg_ok)
        mov   x8, #64
        svc   #0
        b     inicio                                // volver al inicio

chip_malo:
        mov   x0, #1
        ldr   x1, =msg_mal
        mov   x2, #(msg_mal_fin - msg_mal)
        mov   x8, #64
        svc   #0
        b     inicio