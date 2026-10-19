# Laboratorio 02

## Diseño, simulación e implementación de una ALU de 4 bits

---

## Integrantes  

- Julian David Gomez Gonzalez - 1007544331
- Cristian Norbey Hernández Gualteros - 1001091723
- Milton Nicolas Rincón Caicedo - 1021312724

**Semestre:** 2026-2

---

## Índice

1. [Explicación general del funcionamiento](#1-explicación-general-del-funcionamiento)
2. [Descripción de la arquitectura propuesta](#2-descripción-de-la-arquitectura-propuesta)
3. [Explicación de los módulos desarrollados](#3-explicación-de-los-módulos-desarrollados)
4. [Tabla de operaciones implementadas](#4-tabla-de-operaciones-implementadas)
5. [Almacenamiento de operandos](#5-almacenamiento-de-operandos)
6. [Conservación del código de operación](#6-conservación-del-código-de-operación)
7. [Indicadores visuales (LED RGB)](#7-indicadores-visuales-led-rgb)
8. [Simulaciones y Comportamiento Observado en GTKWave](#8-simulaciones-y-comportamiento-observado-en-gtkwave)
9. [Evidencia de la implementación funcional en FPGA](#9-evidencia-de-la-implementación-funcional-en-fpga)
10. [Conclusiones](#conclusiones)

---

## 1. Explicación general del funcionamiento
>
>ad
> **[MILTON]:** Redacte aquí una descripción global de qué hace el sistema. Mencionar qué es una ALU de 4 bits, cómo el usuario ingresa datos por los switches, usa botones para guardar y seleccionar, y ve el resultado en LEDs.

---

## 2. Descripción de la arquitectura propuesta

La arquitectura de este sistema implementa un Datapath, el cual se diseñó separando estrictamente la lógica secuencial (memoria) de la lógica combinacional (procesamiento).

El funcionamiento se divide en tres etapas principales:

1. **Capa de Entrada y Almacenamiento (Lógica Secuencial):**
   Dado que los pines físicos de la FPGA son limitados, se utilizó una técnica de multiplexación en el tiempo. El bus de entrada (4 switches) está conectado simultáneamente a los registros `Reg_A` y `Reg_B`. Los botones físicos (`BTN0` y `BTN1`) actúan como señales de habilitación (*Enable*); al presionarlos, el registro correspondiente captura y memoriza el estado actual de los switches. Por otro lado, un tercer registro (`Reg_Op`) almacena el código de operación de 2 bits, cuyo estado es modificado directamente por los botones `BTN2` y `BTN3`. Todos estos registros están sincronizados con la señal de reloj de la tarjeta (`clk`).

2. **Capa de Procesamiento (Lógica Combinacional):**
   Una vez que los datos están seguros en los registros, viajan por cables internos hacia la **ALU**. La ALU es un módulo puramente combinacional: carece de memoria y de reloj. Su función es evaluar continuamente los valores estáticos presentes en `Reg_A`, `Reg_B` y `Reg_Op`, y calcular el resultado matemático o lógico de forma inmediata.

3. **Capa de Salida:**
   El resultado de 4 bits calculado por la ALU se enruta directamente a los LEDs estándar de la placa. En paralelo, el valor almacenado en el `Reg_Op` alimenta un decodificador que enciende el LED RGB con el color asociado a la operación activa.

**Diagrama de Bloques (Datapath)**

```mermaid
graph LR
    SW[Switches 3:0] --> |Bus de Datos| RegA(Registro A)
    SW --> |Bus de Datos| RegB(Registro B)
    
    BTN0((BTN 0)) -.-> |Señal Enable| RegA
    BTN1((BTN 1)) -.-> |Señal Enable| RegB
    BTN2_3((BTN 2 y 3)) --> |Cambio de Bit| RegOp(Registro OpCode)

    RegA --> |4 bits| ALU{ALU 4-bits}
    RegB --> |4 bits| ALU
    RegOp --> |2 bits| ALU

    ALU --> |Resultado 4 bits| LEDs[LEDs Salida]
    RegOp --> |Decodifica Color| RGB[LED RGB]

    style LEDs fill:#CC5500,stroke:#333
    style RGB fill:#CC5500,stroke:#333
    style SW fill:#CC5500,stroke:#333
    style BTN0 fill:#013220,stroke:#333
    style BTN1 fill:#013220,stroke:#333
    style BTN2_3 fill:#013220,stroke:#333
    style ALU fill:#950606,stroke:#333,stroke-width:2px
    style RegA fill:#003153,stroke:#333
    style RegB fill:#003153,stroke:#333
    style RegOp fill:#003153,stroke:#333

```

---

## 3. Explicación de los módulos desarrollados
>
> **[MILTON]:** Detallar los archivos que usted hizo en Verilog (ej. `alu_4bits.v` y `top_system.v`). Explicar qué hace el Top (hardware e instanciación) y qué hace la ALU.
---

## 4. Tabla de operaciones implementadas

A continuación se resumen las operaciones aritméticas y lógicas que la ALU es capaz de ejecutar. Estas funciones se activan mediante un código de control de 2 bits y operan sobre operandos de 4 bits.

| Código de Operación | Operación | Función Ejecutada |
| :---: | :--- | :--- |
| `00` | **Suma** | `A + B` |
| `01` | **Resta** | `A - B` |
| `10` | **AND lógico** | `A AND B` (Bit a bit) |
| `11` | **OR lógico** | `A OR B` (Bit a bit) |

---

## 5. Almacenamiento de operandos

Para permitir el procesamiento de dos operandos independientes de 4 bits (`A` y `B`) contando únicamente con 4 interruptores físicos (`SW[3:0]`) en la tarjeta Zybo Z7, se diseñó un esquema secuencial de **almacenamiento mediante registros con habilitador de carga (*Clock Enable*)**, aplicando la técnica de **multiplexación en el tiempo**.

### 5.1. Arquitectura de los Registros (Flip-Flops Tipo D)

El almacenamiento se implementa internamente a través de dos registros de 4 bits: `Reg_A` y `Reg_B`. En la FPGA, cada uno de estos registros se sintetiza como un conjunto de **4 Flip-Flops tipo D** síncronos con el reloj del sistema (`clk`).
- **Bus común de datos:** Las entradas de datos ($D$) de ambos registros se encuentran conectadas en paralelo al mismo bus de 4 bits proveniente de los interruptores (`SW[3:0]`).
- **Señales de habilitación independientes (*Enable*):** Cada banco de Flip-Flops cuenta con una línea de control de carga independiente conectada a los pulsadores físicos:
  - `BTN0` actúa como la señal de habilitación (*Load Enable*) para `Reg_A`.
  - `BTN1` actúa como la señal de habilitación (*Load Enable*) para `Reg_B`.

### 5.2. Implementación en Código Verilog

El comportamiento secuencial de captura y persistencia se describe mediante bloques `always` sincronizados por el flanco ascendente del reloj (`posedge clk`), empleando asignaciones no bloqueantes (`<=`):

```verilog
// Registros de almacenamiento para los operandos (4 bits cada uno)
reg [3:0] reg_A = 4'b0000;
reg [3:0] reg_B = 4'b0000;
// Proceso secuencial de captura sincrónica con habilitación
always @(posedge clk) begin
    // Carga del Operando A al presionar BTN0
    if (btn[0]) begin
        reg_A <= sw;
    end
    // Carga del Operando B al presionar BTN1
    if (btn[1]) begin
        reg_B <= sw;
    end
end
```

### 5.3. Principio de Aislamiento y Persistencia de Datos
El uso de registros con habilitación condicional es la clave que permite modificar libremente la posición de los switches sin corromper ni alterar los valores previamente guardados:

1. **Estado de retención (*Hold*):** Cuando un botón no se encuentra presionado (`btn = 0`), la condición de carga no se cumple. En cada flanco positivo de `clk`, los Flip-Flops tipo D mantienen inalterado su estado previo ($Q_{t+1} = Q_t$), ignorando cualquier cambio o conmutación que ocurra en el bus `sw`.
2. **Aislamiento entre operandos:** Al cargar el operando A mediante `BTN0`, el valor queda memorizado. Posteriormente, el usuario puede mover los switches para configurar el operando B; debido a que `BTN0` está inactivo (`0`), el valor de `Reg_A` permanece completamente aislado y protegido. Únicamente al presionar `BTN1` se actualiza `Reg_B`.
3. **Alimentación estática a la ALU:** Las salidas de ambos registros (`reg_A` y `reg_B`) quedan fijas y disponibles de manera simultánea en las entradas de la ALU. Gracias a esto, el módulo combinacional de la ALU evalúa en tiempo real las operaciones matemáticas y lógicas sobre los dos operandos sin fluctuaciones ni dependencias del estado transitorio de los interruptores físicos.

---

## 6. Conservación del código de operación

Para garantizar un funcionamiento estable del sistema y evitar que el usuario deba mantener oprimidos físicamente los pulsadores durante la ejecución o lectura de los resultados, se diseñó un mecanismo de memoria secuencial para el código de operación (`op`).

### 6.1. Limitación de las Entradas Momentáneas (Pulsadores)
Los pulsadores de la placa Zybo Z7 (`BTN0` a `BTN3`) son dispositivos de contacto momentáneo (*push buttons*): generan un nivel lógico alto (`1`) únicamente mientras se ejerce presión física sobre ellos y retornan inmediatamente a nivel bajo (`0`) al ser liberados.

Si el bus selector de operaciones de la ALU (`op[1:0]`) estuviese conectado directamente de forma combinacional a los botones (`op = {BTN3, BTN2}`):
* El código de operación deseado sólo existiría durante el breve instante en que el usuario mantenga el dedo sobre el botón.
* Al soltar el botón, el sistema caería de inmediato a la operación por defecto `00` (Suma).
* Operaciones como el OR lógico (`op = 11`) requerirían que el usuario sostuviera dos botones oprimidos al mismo tiempo con ambas manos mientras intenta observar los LEDs, lo cual resulta impráctico e inestable.

### 6.2. Registro de Estado de 2 Bits (`Reg_Op`)
Para resolver esta limitación, se implementó un registro secuencial de 2 bits denominado `Reg_Op` (`reg [1:0] reg_op`), compuesto por **dos Flip-Flops tipo D** síncronos al reloj `clk`.

Este registro actúa como una memoria de estado estable donde cada pulsador tiene asignada la conmutación y actualización de un bit específico del código:
* **`BTN2` (Bit Menos Significativo - LSB):** Modifica el valor del bit `reg_op[0]`.
* **`BTN3` (Bit Más Significativo - MSB):** Modifica el valor del bit `reg_op[1]`.

Gracias a esta arquitectura, un pulso rápido en `BTN2` o `BTN3` cambia el bit correspondiente, y el nuevo valor queda "enganchado" (*latched*) de forma permanente en los Flip-Flops.

### 6.3. Implementación en Código Verilog
El comportamiento secuencial del registro `Reg_Op` se sintetiza dentro de un bloque `always @(posedge clk)`. El valor inicial por defecto se establece en `2'b00` (Suma), coherente con el encendido inicial del LED RGB en color verde:

```verilog
// Registro de 2 bits para almacenar la operación activa
reg [1:0] reg_op = 2'b00; // Estado inicial: Suma (00)

// Proceso secuencial para conmutar y retener el código de operación
always @(posedge clk) begin
    // BTN2 conmuta el bit 0 (LSB)
    if (btn[2]) begin
        reg_op[0] <= ~reg_op[0];
    end

    // BTN3 conmuta el bit 1 (MSB)
    if (btn[3]) begin
        reg_op[1] <= ~reg_op[1];
    end
end
```

> **Comportamiento en Hardware:** Al detectar la activación del botón en el flanco ascendente de reloj, el flip-flop correspondiente actualiza su salida invirtiendo su estado previo. Cuando el usuario retira el dedo (`btn = 0`), los Flip-Flops entran en modo de **retención (*Hold*)**, conservando indefinidamente el código binario sin importar que los botones físicos se hayan liberado.

### 6.4. Estabilidad del Datapath e Indicación Visual
La persistencia que brinda `Reg_Op` proporciona dos beneficios fundamentales para el funcionamiento global del circuito:
1. **Control ininterrumpido de la ALU:** El código de 2 bits viaja de forma permanente hacia el selector de la ALU combinacional, asegurando que el cálculo activo (`A + B`, `A - B`, `A & B`, o `A | B`) se mantenga procesándose y exhibiéndose de manera continua y estática en los 4 LEDs de salida.
2. **Retroalimentación en el LED RGB:** La señal almacenada en `Reg_Op` alimenta de forma ininterrumpida el decodificador de color (Sección 7). Como se evidencia en las pruebas físicas (Sección 9, Pasos 3 al 6), tras presionar y soltar los pulsadores, el LED RGB permanece fijo en el color correspondiente (Verde, Rojo, Azul o Morado), brindando certeza visual inmediata de la operación retenida en memoria sin necesidad de contacto físico continuo.

---

## 7. Indicadores visuales (LED RGB)

Para facilitar la identificación de la operación que se encuentra actualmente guardada y activa en el sistema, se configuró el LED RGB de la placa Zybo Z7. Los colores para las operaciones aritméticas cumplen con lo solicitado en la guía, mientras que los colores para las operaciones lógicas fueron seleccionados por el grupo buscando un alto contraste visual:

| Operación Activa | Color del LED RGB |
| :--- | :--- |
| **Suma** | 🟢 Verde |
| **Resta** | 🔴 Rojo |
| **AND** | 🔵 Azul |
| **OR** | 🟣 Morado |

---

## 8. Simulaciones y Comportamiento Observado en GTKWave

*Nota: Los archivos fuente del testbench (`tb_alu.v`) y las ondas generadas (`alu_tb.vcd`) se encuentran en la carpeta `sim/` de este repositorio. Al igual que las imágenes colocadas en este apartado.*

El testbench fue diseñado para inyectar estímulos de forma estructurada en 6 pruebas distintas. Al analizar las ondas, se comprueba que el hardware simulado responde exactamente a las sentencias de Verilog, validando tanto la matemática como el comportamiento puramente combinacional de la ALU.

### Prueba 1: Operación Suma (`op = 00`)

![Prueba 1 - Suma](sim/Simulación_Suma.png)

Se realizaron 4 inyecciones de datos para validar sumas normales y casos de desbordamiento (*overflow* limitados a 4 bits):

- `0011 + 0100 = 0111`.
- `0101 + 1010 = 1111` (Valor máximo representable con 4 bits).
- `1100 + 0111 = 10011`. Al superar el límite de 4 bits, la ALU trunca el bit más significativo y arroja `0011`.
- `1111 + 0001 = 10000`. De igual forma, el desbordamiento arroja `0000`.

### Prueba 2: Operación Resta (`op = 01`)

![Prueba 2 - Resta](sim/Simulación_Resta.png)

Se realizaron 4 inyecciones para comprobar restas directas y el manejo de números negativos mediante complemento a 2:

- Restas normales: `1001 - 0100 = 0101` y `0111 - 0111 = 0000`.
- Resultados negativos: `0011 - 0101`. La gráfica muestra un resultado de `1110`, que es la representación correcta de un número negativo (equivalente a `-2` en decimal) usando complemento a 2 para 4 bits. De igual manera, `0000 - 0001` arroja `1111` (equivalente a `-1`).

### Prueba 3: Operación Lógica AND (`op = 10`)

![Prueba 3 - AND](sim/Simulación_AND.png)

Se realizaron 3 inyecciones para validar la operación "bit a bit" (bitwise).

- Al operar `1100 & 1010`, la señal de salida cae a `1000`, encendiendo únicamente la posición donde ambos operandos tienen un `1`. Se verificó también el caso de máscaras opuestas (`1111 & 0101 = 0101`) y la anulación total (`0000 & 1111 = 0000`).

### Prueba 4: Operación Lógica OR (`op = 11`)

![Prueba 4 - OR](sim/Simulación_OR.png)

Con 3 inyecciones adicionales, se verificó la correcta suma lógica bit a bit.

- Al operar `1100 | 1010`, el resultado es `1110`. También se probaron casos de bits independientes (`0001 | 0010 = 0011`) y el caso nulo (`0000 | 0000 = 0000`).

### Prueba 5: Mismos operandos, cambio dinámico de operación

![Prueba 5 - Cambio Op](sim/Simulación_A_B_Fijos.png)

En esta prueba se mantuvieron fijos los operandos en `A = 1100` y `B = 1010`, y se varió únicamente el selector `op` pasando por las 4 operaciones (`00`, `01`, `10`, `11`).
La onda demuestra que la señal `result` se actualiza de manera inmediata (pasando de `0110` a `0010`, luego a `1000` y `1110`). Al no haber retrasos ni depender de flancos de reloj, se certifica el **comportamiento combinacional** exigido en la sección 4.2 del laboratorio.

### Prueba 6: Operador fijo, cambio dinámico de operando A

![Prueba 6 - Cambio A](sim/Simulación_OP_Fijo.png)

Finalmente, se fijó la operación en Suma (`op = 00`) y el operando `B = 0010`. Se inyectaron cambios sucesivos únicamente en el operando `A` (`0001`, `0100` y `1000`). La salida `result` acompañó instantáneamente estos cambios (`0011`, `0110` y `1010`), reconfirmando la sensibilidad inmediata de la ALU a cualquier alteración en su bus de datos.

---

## 9. Evidencia de la implementación funcional en FPGA

El diseño fue sintetizado y programado exitosamente en la tarjeta Zybo Z7. Para la demostración física, se evaluó el sistema ingresando los operandos `A = 1010` y `B = 0101`, y transitando por las 4 operaciones disponibles.

A continuación, se presenta la secuencia fotográfica de la validación en hardware:

### Paso 1: Carga del Operando A

![Carga Operando A](doc/1_Carga_A.jpeg)

Se posicionaron los switches físicos en `1010` y se presionó el botón de carga (`BTN0`). El valor quedó almacenado de forma persistente en el registro A. En este estado inicial, el LED RGB se muestra en color **Verde** indicando que la operación por defecto activa es la Suma.

### Paso 2: Carga del Operando B

![Carga Operando B](doc/2_Carga_B.jpeg)

Se modificó la posición de los switches a `0101` y se presionó el botón de carga (`BTN1`). El sistema demostró que es posible cambiar las entradas físicas sin corromper el dato `1010` previamente guardado en el operando A.

### Paso 3: Operación Suma activa

![Ejecución Suma](doc/3_Suma.jpeg)

Con ambos operandos cargados y la operación Suma activa (`op = 00`), el LED RGB se mantiene **Verde**. Los 4 LEDs estándar ubicados sobre los switches muestran el resultado combinacional en tiempo real: `1010 + 0101 = 1111` (los cuatro LEDs encendidos).

### Paso 4: Cambio a Operación Resta

![Ejecución Resta](doc/4_Resta.jpeg)

Se utilizaron los botones selectores (`BTN2` y `BTN3`) para cambiar el código de operación a Resta (`op = 01`). Tras soltar los botones, el estado se conservó en memoria: el LED RGB cambió a **Rojo** y los LEDs de salida mostraron el resultado correcto: `1010 - 0101 = 0101`.

### Paso 5: Cambio a Operación Lógica AND

![Ejecución AND](doc/5_AND.jpeg)

Se seleccionó la operación AND (`op = 10`). El LED RGB se iluminó en **Azul**. Dado que los operandos utilizados tienen bits complementarios y no comparten ningún `1` en la misma posición (`1010 & 0101`), el resultado lógico es `0000`. La fotografía evidencia que los 4 LEDs de salida se apagaron correctamente.

### Paso 6: Cambio a Operación Lógica OR

![Ejecución OR](doc/6_OR.jpeg)

Finalmente, se seleccionó la operación OR (`op = 11`). El LED RGB cambió a **Morado**, cumpliendo con la asignación visual definida por el grupo. El resultado de sumar lógicamente `1010 | 0101` es `1111`, por lo que los 4 LEDs volvieron a encenderse simultáneamente.

---

## 10. Conclusiones

1. Se comprobó la importancia crítica de separar la lógica combinacional de la secuencial. Al aislar la ALU en su propio módulo independiente sin señales de reloj, se obtuvo un bloque de procesamiento puro y estructurado. Esto garantiza que el código sea escalable y fácilmente reutilizable como una "caja negra" para los sistemas de mayor complejidad que se desarrollarán en los próximos laboratorios.
2. El laboratorio demostró cómo el uso de elementos de memoria (Flip-Flops/Registros) permite superar las limitaciones físicas de la FPGA. Mediante la "multiplexación en el tiempo", se logró que un solo bus de 4 switches alimentara un sistema que en la práctica requiere 10 bits simultáneos para operar (dos operandos de 4 bits y un código de 2 bits).
3. El uso de Icarus Verilog y GTKWave fue fundamental para aislar errores. Diseñar un *testbench* riguroso permitió comprobar matemáticamente casos críticos (como el comportamiento en números negativos por complemento a 2 y los desbordamientos) antes de invertir tiempo en la síntesis y programación del hardware físico, garantizando que la ALU funcionara correctamente en la placa Zybo desde el primer intento.
