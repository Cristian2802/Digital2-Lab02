module alu (                    // Esto es el modulo de la ALU :)
    input  wire [3:0] A,       // Operando A (4 bits)
    input  wire [3:0] B,       // Operando B (4 bits)
    input  wire [1:0] op,      // Código de operación (2 bits)
    output reg  [3:0] result   // Resultado (4 bits)
);
 
    // always @(*): el bloque se reevalúa cada vez que cambia
    // cualquier entrada -> comportamiento combinacional. // 
    always @(*) begin
        case (op)
            2'b00:   result = A + B;   // Suma
            2'b01:   result = A - B;   // Resta
            2'b10:   result = A & B;   // AND bit a bit
            2'b11:   result = A | B;   // OR bit a bit
            default: result = 4'b0000; // Evita latches
        endcase
    end
 
endmodule
