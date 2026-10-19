// ============================================================
// almacenamiento.v - Elementos secuenciales del sistema
// Lab02 - Electrónica Digital 2
//
// Contiene los módulos con memoria (flip-flops). Todos usan
// always @(posedge clk). La ALU NO está aquí: es combinacional
// y vive en alu.v.
//
//   registro     -> guarda el Operando A o el Operando B
//   antirrebote  -> limpia un botón y entrega 1 pulso por pulsación
//   control_op   -> guarda el código de operación de 2 bits
// ============================================================


// ============================================================
// registro - Registro de 4 bits con carga (load)
//
// En cada flanco de subida del reloj:
//   load = 1 -> copia el dato de entrada (switches)
//   load = 0 -> conserva el valor anterior (memoria)
// ============================================================
module registro (
    input  wire       clk,            // reloj
    input  wire       load,           // 1 = cargar el dato, 0 = conservar
    input  wire [3:0] d,              // dato de entrada (bus de switches)
    output reg  [3:0] q = 4'b0000     // valor guardado (arranca en 0)
);

    always @(posedge clk) begin
        if (load)
            q <= d;     // captura el valor de los switches
        // si load = 0 no se asigna nada: q conserva su valor
    end

endmodule


// ============================================================
// antirrebote - Antirrebote y detector de pulsación
//
// Recibe la señal "sucia" de un botón mecánico y entrega un
// pulso limpio de UN solo ciclo de reloj cada vez que el botón
// se presiona. Una pulsación = un pulso, sin importar el rebote
// ni cuánto tiempo se mantenga presionado.
//
//   1. Sincronizador: pasa el botón por dos flip-flops.
//   2. Filtro: acepta un cambio solo si dura 10 ms estable.
//   3. Detector de flanco: pulso cuando el botón limpio pasa 0 -> 1.
// ============================================================
module antirrebote (
    input  wire clk,          // reloj de 125 MHz
    input  wire btn,          // botón físico (con rebotes)
    output reg  pulso = 1'b0  // pulso de 1 ciclo al presionar
);

    // 10 ms a 125 MHz = 0.010 * 125_000_000 = 1_250_000 ciclos
    localparam LIMITE = 1_250_000;

    reg        sync0    = 1'b0;   // etapa 1 del sincronizador
    reg        sync1    = 1'b0;   // etapa 2 del sincronizador
    reg        estable  = 1'b0;   // estado limpio del botón
    reg [20:0] contador = 21'd0;  // cuenta hasta 1_250_000 (cabe en 21 bits)

    always @(posedge clk) begin
        // 1. Sincronizador
        sync0 <= btn;
        sync1 <= sync0;

        // Por defecto no hay pulso (dura solo 1 ciclo)
        pulso <= 1'b0;

        // 2. Filtro de rebotes
        if (sync1 == estable) begin
            contador <= 21'd0;                  // sin cambio: reiniciar
        end else begin
            contador <= contador + 1'b1;        // entrada distinta: contar

            if (contador == LIMITE - 1) begin   // 10 ms estable: cambio real
                estable  <= sync1;
                contador <= 21'd0;

                // 3. Detector de flanco: solo al presionar (0 -> 1)
                if (sync1 == 1'b1)
                    pulso <= 1'b1;
            end
        end
    end

endmodule


// ============================================================
// control_op - Registro del código de operación
//
// Cada pulso invierte (0 <-> 1) el bit correspondiente:
//   pulso_bit0 (desde BTN2) -> invierte op[0]
//   pulso_bit1 (desde BTN3) -> invierte op[1]
// El valor se conserva después de soltar los botones.
// ============================================================
module control_op (
    input  wire       clk,
    input  wire       pulso_bit0,     // pulso limpio de BTN2
    input  wire       pulso_bit1,     // pulso limpio de BTN3
    output reg  [1:0] op = 2'b00      // arranca en 00 (suma)
);

    always @(posedge clk) begin
        if (pulso_bit0)
            op[0] <= ~op[0];          // invierte el bit 0
        if (pulso_bit1)
            op[1] <= ~op[1];          // invierte el bit 1
    end

endmodule
