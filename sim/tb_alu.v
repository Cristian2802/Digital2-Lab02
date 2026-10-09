`timescale 1ns/1ps   // unidad de tiempo = 1 ns, precisión = 1 ps
 
module tb_alu;       

    // Señales de prueba

    reg  [3:0] A;
    reg  [3:0] B;
    reg  [1:0] op;
    wire [3:0] result;
 
    // Instancia de la ALU (Unit Under Test)

    alu uut (
        .A      (A),
        .B      (B),
        .op     (op),
        .result (result)
    );
 
    // Secuencia de pruebas

    initial begin
        // Archivo de ondas para GTKWave
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, tb_alu);
 
        // Imprime una línea en consola cada vez que cambia alguna señal
        $monitor("%4t ns | op=%b | A=%b (%2d)  B=%b (%2d) | result=%b (%2d)",
                 $time, op, A, A, B, B, result, result);
 
        // ---------- Prueba 1: SUMA (op = 00) ----------
        A = 4'd3;  B = 4'd4;  op = 2'b00;  #10;   // esperado:  7
        A = 4'd5;  B = 4'd10; op = 2'b00;  #10;   // esperado: 15 (máximo sin desbordar)
        A = 4'd12; B = 4'd7;  op = 2'b00;  #10;   // esperado:  3 (19 desborda)
        A = 4'd15; B = 4'd1;  op = 2'b00;  #10;   // esperado:  0 (16 desborda)
 
        // ---------- Prueba 2: RESTA (op = 01) ----------
        A = 4'd9;  B = 4'd4;  op = 2'b01;  #10;   // esperado:  5
        A = 4'd7;  B = 4'd7;  op = 2'b01;  #10;   // esperado:  0
        A = 4'd3;  B = 4'd5;  op = 2'b01;  #10;   // esperado: 14 (1110 = -2)
        A = 4'd0;  B = 4'd1;  op = 2'b01;  #10;   // esperado: 15 (1111 = -1)
 
        // ---------- Prueba 3: AND (op = 10) ----------
        A = 4'b1100; B = 4'b1010; op = 2'b10; #10; // esperado: 1000
        A = 4'b1111; B = 4'b0101; op = 2'b10; #10; // esperado: 0101
        A = 4'b0000; B = 4'b1111; op = 2'b10; #10; // esperado: 0000
 
        // ---------- Prueba 4: OR (op = 11) ----------
        A = 4'b1100; B = 4'b1010; op = 2'b11; #10; // esperado: 1110
        A = 4'b0001; B = 4'b0010; op = 2'b11; #10; // esperado: 0011
        A = 4'b0000; B = 4'b0000; op = 2'b11; #10; // esperado: 0000
 
        // ---------- Prueba 5: mismos operandos, solo cambia op ----------
        A = 4'd12; B = 4'd10;
        op = 2'b00; #10;                           // esperado: 6    (22 desborda)
        op = 2'b01; #10;                           // esperado: 2
        op = 2'b10; #10;                           // esperado: 1000
        op = 2'b11; #10;                           // esperado: 1110
 
        // ---------- Prueba 6: op fijo (suma), solo cambia A ----------
        op = 2'b00; B = 4'd2;
        A = 4'd1; #10;                             // esperado:  3
        A = 4'd4; #10;                             // esperado:  6
        A = 4'd8; #10;                             // esperado: 10
 
        $finish;
    end
 
endmodule
 