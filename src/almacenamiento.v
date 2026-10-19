// En cada flanco de subida del reloj:
//  load = 1 -> copia el dato de entrada (switches)
//  load = 0 -> conserva el valor anterior (memoria)

module registro (
    input  wire       clk,            // reloj
    input  wire       load,           // 1 = cargar el dato, 0 = conservar
    input  wire [3:0] d,              // dato de entrada (bus de switches)
    output reg  [3:0] q = 4'b0000     // valor guardado (arranca en 0)
);

    always @(posedge clk) begin
        if (load)
            q <= d;     // captura el valor de los switches
        // si load = 0 no se asigna nada
    end

endmodule


// ============================================================
// antirrebote - Antirrebote y detector de pulsación

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


module control_op (
    input  wire       clk,
    input  wire       pulso_bit0,     // pulso de BTN2
    input  wire       pulso_bit1,     // pulso  de BTN3
    output reg  [1:0] op = 2'b00      // arranca en 00 (suma)
);

    always @(posedge clk) begin
        if (pulso_bit0)
            op[0] <= ~op[0];          // invierte el bit 0
        if (pulso_bit1)
            op[1] <= ~op[1];          // invierte el bit 1
    end

endmodule
