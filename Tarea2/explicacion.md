# Explicacion del Programa 

Tenemos 3 compuertas de 2 Entradas `NAND`, `AND`, `OR`, Entonces dichas entradas 
tiene combinaciones para ver su funcionalidad a traves de una tabla de valor, pero todas tiene 2 entradas eso quiere decir que tienen las misma combinaciones pero no los mismo resultados 

| Entrada A | Entrada B | NAND (7400) | OR (7432) | AND (7408) |
|:---------:|:---------:|:-----------:|:--------:|:----------:|
| 0         | 0         | 1           | 0        | 0          |
| 0         | 1         | 1           | 1        | 0          |
| 1         | 0         | 1           | 1        | 0          |
| 1         | 1         | 0           | 1        | 1          |


Entonces para nuestros ejemplos de pruebas vamos a utilizar esas combinaciones de las entradas A y B, pero como estamos trabajando con compuertas debemos tener en cuenta cada entrada de cada una de ellas. 

| Pin | 1   | 2   | 3  | 4  | 5  | 6  | 8  | 9  | 10 | 11 | 12 | 13 |
|-----|-----|-----|----|----|----|----|----|----|----|----|----|----|
| Bit | D11 | D10 | D9 | D8 | D7 | D6 | D5 | D4 | D3 | D2 | D1 | D0 |

> Tenemos nuestra Entradas y salidas de cada compuerta en total tenemos 4 de ellas. Entradas(D11, D10, D8, D7, D5, D4, D2, D1) salidas (D9, D6, D3, D0)

a cada una de las entradas debemos colocarle la combinacion que tenemos en la tabla de verdad. 

Entonces comenzamos de esta manera: 

Entradas A = 0  B = 0 

| Pin | 1   | 2   | 3  | 4  | 5  | 6  | 8  | 9  | 10 | 11 | 12 | 13 |
|-----|-----|-----|----|----|----|----|----|----|----|----|----|----|
| Bit | 0   |   0 | D9 | 0  | 0  | D6 | 0  | 0  | 0  | D2 | 0  | 0  |

y lo demas que son las salidas serian 0 porque eso es lo que nos deberia dar la parte del hadware, entonces como en la totalidad son 12 bits entonces los vamos a usar en Hexadecimal que seria `0x000`. 

Entradas A = 0  B = 1 

| Pin | 1   | 2   | 3  | 4  | 5  | 6  | 8  | 9  | 10 | 11 | 12 | 13 |
|-----|-----|-----|----|----|----|----|----|----|----|----|----|----|
| Bit | 0   | 1   | D9 | 0  | 1  | D6 | D8 | 0  | 1  | 0  | 0  | 1  |

Entonces seguimos aplicando el mismo patron para cada entrada y asi cuando le apliquemos (OR, AND, NAND) esta nos de un resultado diferente , entonces una vez tengamos esto como bien sabemos la parte de salidas sigue siendo 0 entonces los 12 bits nos quedaria asi 
0100 1000 1001-> 12 bits y eso lo pasamos a hexadecimal `0x489`

| Pin | 1   | 2   | 3  | 4  | 5  | 6  | 8  | 9  | 10 | 11 | 12 | 13 |
|-----|-----|-----|----|----|----|----|----|----|----|----|----|----|
| Bit | 0   | 1   | 0  | 0  | 1  | 0  | 0  | 0  | 1  | 0  | 0  | 1  |

y asi no vamos sucesivamente con las otras dos combinaciones restantes. 



## Explicación de las salidas esperadas y los bits de salida

### 1. Salidas esperadas

En esta parte del código guardamos los resultados que debería dar cada circuito integrado si funciona correctamente.

```asm
esperado_7400: .word 1, 1, 1, 0
esperado_7408: .word 0, 0, 0, 1
esperado_7432: .word 0, 1, 1, 1
esperado_7427: .word 1, 0, 0, 0, 0, 0, 0, 0
```

Como las compuertas de dos entradas tienen cuatro combinaciones posibles (`00`, `01`, `10` y `11`), guardamos cuatro resultados para cada una. En el caso del 7427, como es una compuerta NOR de tres entradas, tenemos ocho combinaciones posibles y por eso guardamos ocho resultados.

Cada integrado tiene resultados diferentes según su función lógica:

- **7400 (NAND):** sus salidas son `1, 1, 1, 0`.
- **7408 (AND):** sus salidas son `0, 0, 0, 1`.
- **7432 (OR):** sus salidas son `0, 1, 1, 1`.
- **7427 (NOR):** su salida es `1` cuando las tres entradas son `0`; en las demás combinaciones es `0`.

De esta manera, el programa puede comparar el resultado que devuelve el hardware con el resultado que debería obtener. Si son diferentes, significa que se ha detectado un posible fallo.

### 2. Bits de salida de cada compuerta

```asm
bits_salida_2: .word 0x200, 0x040, 0x020, 0x004
bits_salida_3: .word 0x002, 0x040, 0x020
```

Estas tablas indican la posición de los bits donde se encuentran las salidas de las compuertas dentro del registro `X0`.

Recordemos que cada bit de `X0` corresponde a un pin del circuito integrado. Por ejemplo, el bit `D9` corresponde al pin 3, el bit `D6` al pin 6 y el bit `D5` al pin 8.

Utilizamos valores hexadecimales para identificar cada posición de forma sencilla:

| Valor hexadecimal | Bit que representa | Pin correspondiente |
|---|---|---|
| `0x200` | D9 | 3 |
| `0x040` | D6 | 6 |
| `0x020` | D5 | 8 |
| `0x004` | D2 | 11 |
| `0x002` | D1 | 12 |

Por ejemplo, `0x200` representa el bit D9. Al utilizar esta máscara, el programa puede comprobar el estado de esa salida sin tener en cuenta los demás bits.

En los integrados 7400, 7408 y 7432 guardamos cuatro posiciones porque cada uno contiene cuatro compuertas. En el 7427 guardamos tres posiciones porque contiene tres compuertas NOR.

### Conclusión

Las tablas de salidas esperadas permiten conocer que resultado logico debe producir cada integrado, mientras que las tablas de bits de salida permiten localizar las salidas de cada compuerta dentro de `X0` ambas son necesarias para comparar los resultados obtenidos con los esperados e identificar si el circuito integrado funciona correctamente o presenta alguna compuerta dañada.