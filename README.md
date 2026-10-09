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
9. [Implementación funcional en FPGA](#10-implementación-funcional-en-fpga)

---

## 1. Explicación general del funcionamiento
> **[📝 NOTA PARA JULIAN]:** Redacta aquí una descripción global de qué hace el sistema. Menciona que es una ALU de 4 bits, cómo el usuario ingresa datos por los switches, usa botones para guardar y seleccionar, y ve el resultado en LEDs.

---

## 2. Descripción de la arquitectura propuesta
> **[📝 NOTA PARA MILTON]:** Describe aquí la estructura del datapath simplificado. Habla de la separación entre la lógica secuencial (registros) y combinacional (ALU). 

---

## 3. Explicación de los módulos desarrollados
> **[📝 NOTA PARA MILTON]:** Detalla los archivos Verilog (ej. `alu_4bits.v` y `top_system.v`). Explica qué hace el Top (hardware e instanciación) y qué hace la ALU (solo matemáticas sin memoria).

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
> **[📝 NOTA PARA JULIAN]:** Explica cómo se usan los flip-flops/registros en el código para guardar el Operando A y B, y cómo esto permite cambiar los switches sin afectar los valores ya guardados.

## 6. Conservación del código de operación
> **[📝 NOTA PARA JULIAN]:** Explica cómo funciona el registro de 2 bits que guarda la selección de la operación al presionar BTN2 y BTN3, evitando que el usuario tenga que dejarlos oprimidos.

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
*Nota: Los archivos fuente del testbench (`tb_alu.v`) y las ondas generadas (`alu_tb.vcd`) se encuentran en la carpeta `sim/` de este repositorio.*

El testbench fue diseñado para inyectar estímulos de forma estructurada en 6 pruebas distintas. Al analizar las ondas, se comprueba que el hardware simulado responde exactamente a las sentencias de Verilog, validando tanto la matemática como el comportamiento puramente combinacional de la ALU.

### Prueba 1: Operación Suma (`op = 00`)
![Prueba 1 - Suma](sim/Simulación_Suma.png)

Se realizaron 4 inyecciones de datos para validar sumas normales y casos de desbordamiento (*overflow* limitados a 4 bits):
*   `3 + 4 = 7`.
*   `5 + 10 = 15` (Valor máximo representable con 4 bits).
*   `12 + 7 = 19`. Al superar el límite de 4 bits (`10011`), la ALU trunca el bit más significativo y arroja `3` (`0011`).
*   `15 + 1 = 16`. De igual forma, el desbordamiento arroja `0` (`0000`).

### Prueba 2: Operación Resta (`op = 01`)
![Prueba 2 - Resta](sim/Simulación_Resta.png)

Se realizaron 4 inyecciones para comprobar restas directas y el manejo de números negativos mediante complemento a 2:
*   Restas normales: `9 - 4 = 5` y `7 - 7 = 0`.
*   Resultados negativos: `3 - 5 = -2`. La gráfica muestra un resultado de `14` (`1110` en binario), que es la representación correcta de `-2` en complemento a 2 para 4 bits. De igual manera, `0 - 1 = -1` arroja `15` (`1111`).

### Prueba 3: Operación Lógica AND (`op = 10`)
![Prueba 3 - AND](sim/Simulación_AND.png)

Se realizaron 3 inyecciones para validar la operación "bit a bit" (bitwise). 
*   Al operar `1100 & 1010`, la señal de salida cae a `1000`, encendiendo únicamente la posición donde ambos operandos tienen un `1`. Se verificó también el caso de máscaras opuestas (`1111 & 0101 = 0101`) y la anulación total (`0000 & 1111 = 0000`).

### Prueba 4: Operación Lógica OR (`op = 11`)
![Prueba 4 - OR](sim/Simulación_OR.png)

Con 3 inyecciones adicionales, se verificó la correcta suma lógica bit a bit.
*   Al operar `1100 | 1010`, el resultado es `1110`. También se probaron casos de bits independientes (`0001 | 0010 = 0011`) y el caso nulo (`0000 | 0000 = 0000`).

### Prueba 5: Mismos operandos, cambio dinámico de operación
![Prueba 5 - Cambio Op](sim/Simulación_A_B_Fijos.png)

En esta prueba se mantuvieron fijos los operandos en `A = 12` y `B = 10`, y se varió únicamente el selector `op` pasando por las 4 operaciones (`00`, `01`, `10`, `11`). 
La onda demuestra que la señal `result` se actualiza de manera inmediata (pasando de `6` a `2`, luego a `1000` y `1110`). Al no haber retrasos ni depender de flancos de reloj, se certifica el **comportamiento combinacional** exigido en la sección 4.2 del laboratorio.

### Prueba 6: Operador fijo, cambio dinámico de operando A
![Prueba 6 - Cambio A](sim/Simulación_OP_Fijo.png)

Finalmente, se fijó la operación en Suma (`op = 00`) y el operando `B = 2`. Se inyectaron cambios sucesivos únicamente en el operando `A` (`1`, `4` y `8`). La salida `result` acompañó instantáneamente estos cambios (`3`, `6` y `10`), reconfirmando la sensibilidad inmediata de la ALU a cualquier alteración en su bus de datos.

## 10. Implementación funcional en FPGA
*(Sección a cargo de Cristian)*
**[AQUÍ PONDREMOS LAS FOTOS DE LA TARJETA ZYBO Y TU DESCRIPCIÓN DE CÓMO SE PROBÓ EN FÍSICO]**

---
