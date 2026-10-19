// ============================================================
// top.v - Módulo superior del sistema
// Lab02 - Electrónica Digital 2
//
// Conecta los recursos físicos de la Zybo Z7 con el diseño.
// NO contiene operaciones aritméticas ni lógicas: solo instancia
// y conecta los módulos.
//
//   sw[3:0]  -> bus de datos compartido
//   btn[0]   -> cargar Operando A
//   btn[1]   -> cargar Operando B
//   btn[2]   -> invertir bit 0 del código de operación
//   btn[3]   -> invertir bit 1 del código de operación
//   led[3:0] -> resultado de la ALU
//   led6_*   -> LED RGB (LD6): color según la operación
//
// También contiene el módulo rgb_decoder (combinacional).
// ============================================================

module top (
    input  wire       clk,      // reloj de 125 MHz
    input  wire [3:0] sw,       // switches: bus de datos
    input  wire [3:0] btn,      // botones
    output wire [3:0] led,      // LEDs: resultado
    output wire       led6_r,   // LED RGB 6: rojo
    output wire       led6_g,   // LED RGB 6: verde
    output wire       led6_b    // LED RGB 6: azul
);

    // --------------------------------------------------------
    // Cables internos
    // --------------------------------------------------------
    wire [3:0] reg_a;       // Operando A guardado
    wire [3:0] reg_b;       // Operando B guardado
    wire [1:0] reg_op;      // Código de operación guardado
    wire       pulso_op0;   // pulso limpio de BTN2
    wire       pulso_op1;   // pulso limpio de BTN3

    // --------------------------------------------------------
    // Registros de operandos (BTN0 -> A, BTN1 -> B)
    // Ambos escuchan el mismo bus (sw); cada botón decide
    // cuál registro guarda. No necesitan antirrebote: cargar
    // el mismo valor varias veces no cambia el resultado.
    // --------------------------------------------------------
    registro reg_A (
        .clk  (clk),
        .load (btn[0]),
        .d    (sw),
        .q    (reg_a)
    );

    registro reg_B (
        .clk  (clk),
        .load (btn[1]),
        .d    (sw),
        .q    (reg_b)
    );

    // --------------------------------------------------------
    // Antirrebote de los botones de operación (BTN2, BTN3)
    // --------------------------------------------------------
    antirrebote ar_op0 (
        .clk   (clk),
        .btn   (btn[2]),
        .pulso (pulso_op0)
    );

    antirrebote ar_op1 (
        .clk   (clk),
        .btn   (btn[3]),
        .pulso (pulso_op1)
    );

    // --------------------------------------------------------
    // Registro del código de operación
    // --------------------------------------------------------
    control_op ctrl_op (
        .clk        (clk),
        .pulso_bit0 (pulso_op0),
        .pulso_bit1 (pulso_op1),
        .op         (reg_op)
    );

    // --------------------------------------------------------
    // ALU (combinacional): resultado directo a los LEDs
    // --------------------------------------------------------
    alu mi_alu (
        .A      (reg_a),
        .B      (reg_b),
        .op     (reg_op),
        .result (led)
    );

    // --------------------------------------------------------
    // Indicador de operación en el LED RGB
    // --------------------------------------------------------
    rgb_decoder dec_rgb (
        .op (reg_op),
        .r  (led6_r),
        .g  (led6_g),
        .b  (led6_b)
    );

endmodule


// ============================================================
// rgb_decoder - Traduce el código de operación a un color
// Combinacional: el color depende solo del opcode actual.
//
//   op   Operación   Color     R G B
//   00   Suma        Verde     0 1 0
//   01   Resta       Rojo      1 0 0
//   10   AND         Azul      0 0 1
//   11   OR          Morado    1 0 1
// ============================================================
module rgb_decoder (
    input  wire [1:0] op,
    output reg        r,
    output reg        g,
    output reg        b
);

    always @(*) begin
        case (op)
            2'b00:   {r, g, b} = 3'b010;   // Suma  -> verde
            2'b01:   {r, g, b} = 3'b100;   // Resta -> rojo
            2'b10:   {r, g, b} = 3'b001;   // AND   -> azul
            2'b11:   {r, g, b} = 3'b101;   // OR    -> morado
            default: {r, g, b} = 3'b000;   // apagado
        endcase
    end

endmodule
