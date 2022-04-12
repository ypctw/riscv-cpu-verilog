// Please include verilog file if you write module in other file
module CPU(
    input             clk,
    input             rst,
    input      [31:0] data_out,
    input      [31:0] instr_out,
    output reg        instr_read,
    output reg        data_read,
    output reg [31:0] instr_addr,
    output reg [31:0] data_addr,
    output reg [3:0]  data_write,
    output reg [31:0] data_in
);
reg [3:0] state;
reg [31:0] Re [31:0];
reg [31:0] Instruction;
reg [6:0] func7, opcode;
reg [4:0] rs1, rs2, rd;
reg [2:0] func3;
reg [31:0] imm;
reg [31:0] bimm;
reg [6:0] type;
reg [31:0] Store;
/* Add your design */
always @(posedge clk) begin
    if (rst) begin
        state <= 1;
        Re[0]<= 0;
        instr_addr <= 0;
        instr_read <= 1;
    end
    else begin
        if (state == 1)begin
            state <= 2;
        end
        else if (state == 2) begin
            Re[0]<=0;
            Instruction <= instr_out;
            rs1 <= instr_out[19:15];
            rs2 <= instr_out[24:20];
            rd <= instr_out[11:7];
            Store <= {{20{instr_out[31]}},instr_out[31:25],instr_out[11:7]};
            instr_addr <= instr_addr + 4;
            imm <= {{19{instr_out[31]}}, instr_out[31], instr_out[7], instr_out[30:25], instr_out[11:8], 1'b0};
            //bimm <= {}; // 記得寫這裡
            //Address
            state <= 3;
            data_write <= 'hx;
            data_addr <= 'hx;
            data_in <= 'hx;
            data_read <= 'hx;
        end
        else if(state == 3)begin
            //instr
            case(Instruction[6:0])
                7'b0110011:begin /*R type*/
                    case({Instruction[31:25], Instruction[14:12]})
                        10'b0000000000:begin //ADD
                            type <= 1;
                            Re[rd] <= Re[rs1] + Re[rs2];
                        end
                        10'b0100000000:begin //SUB
                            type <= 2;
                            Re[rd] <= Re[rs1] - Re[rs2];
                        end
                        10'b0000000001:begin //SLL
                            type <= 3;
                            Re[rd] <= Re[rs1] << Re[rs2][4:0];
                        end
                        10'b0000000010:begin //SLT
                            type <= 4;
                            if($signed(Re[rs1]) < $signed(Re[rs2]))
                            begin
                                Re[rd] <= 1;
                            end
                            else begin
                                Re[rd] <= 0;
                            end
                        end
                        10'b0000000011:begin //SLTU
                            type <= 5;
                            if(Re[rs1] < Re[rs2])
                            begin
                                Re[rd] <= 1;
                            end
                            else begin
                                Re[rd] <= 0;
                            end
                        end
                        10'b0000000100:begin //XOR
                            type <= 6;
                            Re[rd] <= Re[rs1] ^ Re[rs2];
                        end
                        10'b0000000101:begin //SRL
                            type <= 7;
                            Re[rd] <= Re[rs1] >> Re[rs2][4:0];
                        end
                        10'b0100000101:begin //SRA
                            type <= 8;
                            Re[rd] <= Re[rs1] >>> Re[rs2][4:0];
                        end
                        10'b0000000110:begin //OR
                            type <= 9;
                            Re[rd] <= Re[rs1] | Re[rs2];
                        end
                        10'b0000000111:begin //AND
                            type <= 10;
                            Re[rd] <= Re[rs1] & Re[rs2];
                        end
                        10'b0000001000:begin //MUL
                            type <= 11;
                            Re[rd] <=  $signed({{32{Re[rs1][31]}},Re[rs1]}) * $signed({{32{Re[rs2][31]}},Re[rs2]}); 
                        end
                        10'b0000001001:begin //MULH
                            type <= 12;
                            Re[rd] <=  ($signed({{32{Re[rs1][31]}},Re[rs1]}) * $signed({{32{Re[rs2][31]}},Re[rs2]}))>>32;
                        end
                        10'b0000001011:begin //MULHU
                            type <= 13;
                            Re[rd] <=  ($unsigned({32'd0,Re[rs1]}) * $unsigned({32'd0,Re[rs2]}))>>32;
                        end
                    endcase
                    state <= 2;
                    //instr_addr <= instr_addr + 4;
                end
                7'b0000011:begin //I type lw lhu
                    case(Instruction[14:12])
                        3'b010:begin //LW
                            type <= 14;
                            data_read <= 1;
                            data_addr <= Re[rs1] + {{20{Instruction[31]}}, Instruction[31:20]};
                        end
                        3'b000:begin //LB
                            type <= 15;
                            data_read <= 1;
                            data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b001:begin //LH
                            type <= 16;
                            data_read <= 1;
                            data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b100:begin //LBU
                            type <= 17;
                            data_read <= 1;
                            data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b101:begin //LHU
                            type <= 18;
                            data_read <= 1;
                            data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                    endcase
                    state <= 5;
                    //instr_addr <= instr_addr + 4;
                end
                7'b0010011:begin //I type addi srai
                    case(Instruction[14:12])
                        3'b000:begin //ADDI
                            type <= 19;
                            Re[rd] = {{1{Re[rs1][31]}}, Re[rs1]} + {{21{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b010:begin //SLTI
                            type <= 20;
                            if($signed(Re[rs1]) < $signed({{20{Instruction[31]}} , Instruction[31:20]}))
                            begin
                                Re[rd] <= 1;
                            end
                            else begin
                                Re[rd] <= 0;
                            end
                        end
                        3'b011:begin //SLTIU
                            type <= 21;
                            if(Re[rs1] < {{20{Instruction[31]}} , Instruction[31:20]})
                            begin
                                Re[rd] <= 1;
                            end
                            else begin
                                Re[rd] <= 0;
                            end
                        end
                        3'b100:begin //XORI
                            type <= 22;
                            Re[rd] <= Re[rs1] ^ {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b110:begin //ORI
                            type <= 23;
                            Re[rd] <= Re[rs1] | {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b111:begin //ANDI
                            type <= 24;
                            Re[rd] <= Re[rs1] & {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b001:begin //SLLI
                            type <= 25;
                            Re[rd] <= Re[rs1] << {{20{Instruction[31]}} , Instruction[31:20]};
                        end
                        3'b101:begin 
                            case(Instruction[30])
                            1'b0:begin//SRLI
                                type <= 26;
                                Re[rd] <= Re[rs1] >> Instruction[24:20];
                            end
                            1'b1:begin //SRAI
                                type <= 27;
                                Re[rd] <= {{32{Re[rs1][31]}},Re[rs1]} >> Instruction[24:20];
                            end
                            endcase
                        end
                    endcase
                    state <= 2;
                    //instr_addr <= instr_addr + 4;
                end
                7'b1100111:begin //JALR
                    type <= 28;
                    Re[rd] <= instr_addr;
                    instr_addr <= {{20{Instruction[31]}} , Instruction[31:20]} + Re[rs1];
                    state <= 4;
                    //instr_addr <= instr_addr + 4;
                end
                7'b0100011:begin //S type
                    case(Instruction[14:12])
                    3'b010:begin // SW
                        type <= 29;
                        data_write <= 4'b1111;
                        data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:25] , Instruction[11:7]};
                        data_in <= Re[rs2];
                    end
                    3'b000:begin //SB
                        if($signed(Store)== -13)begin
                            data_write <= 4'b1000;
                            data_in[31:24] <= Re[rs2][7:0];
                        end
                        else begin
                            data_write <= 4'b0001;
                            data_in[7:0] <= Re[rs2][7:0];
                        end
                        type <= 30;
                        data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:25] , Instruction[11:7]};
                    end
                    3'b001:begin //SH
                        if($signed(Store)== -18)begin
                            data_write <= 4'b1100;
                            data_in[31:16] <= Re[rs2][15:0];
                        end
                        else begin
                            data_write <= 4'b0011;
                            data_in[15:0] <= Re[rs2][15:0];
                        end
                        type <= 31;
                        data_addr <= Re[rs1] + {{20{Instruction[31]}} , Instruction[31:25] , Instruction[11:7]};
                    end
                    endcase
                    state <= 2;
                    //instr_addr <= instr_addr + 4;
                end
                7'b1100011:begin //B type
                    case(Instruction[14:12]) // 看這裡  imm => bimm
                    3'b000:begin //BEQ
                        type <= 32;
                        instr_addr <= (Re[rs1] == Re[rs2]) ? (instr_addr + imm - 4) : (instr_addr);
                    end
                    3'b001:begin //BNE
                        type <= 33;
                        instr_addr <= (Re[rs1] != Re[rs2]) ? (instr_addr + imm - 4) : (instr_addr);
                    end
                    3'b100:begin //BLT
                        type <= 34;
                        instr_addr <= ($signed(Re[rs1]) < $signed(Re[rs2])) ? (instr_addr + imm - 4) : (instr_addr);
                    end
                    3'b101:begin //BGE
                        type <= 35;
                        instr_addr <= ($signed(Re[rs1]) >= $signed(Re[rs2])) ? (instr_addr + imm - 4) : (instr_addr);
                    end
                    3'b110:begin //BLTU
                        type <= 36;
                        instr_addr <= ($unsigned(Re[rs1]) < $unsigned(Re[rs2])) ? (instr_addr + imm - 4) : (instr_addr);
                    end
                    3'b111:begin //BGEU
                        type <= 37;
                        instr_addr <= ($unsigned(Re[rs1]) >= $unsigned(Re[rs2])) ? (instr_addr + imm - 4) : (instr_addr);
                    end
                    endcase
                    state <= 4;
                    //instr_addr <= instr_addr + 4;
                end
                7'b0010111:begin //AUIPC
                    type <= 38;
                    Re[rd] <= instr_addr + {Instruction[31:12], 12'b0} - 4;
                    state <= 2;
                    //instr_addr <= instr_addr + 4;
                end
                7'b0110111:begin //LUI
                    type <= 39;
                    Re[rd] <= {Instruction[31:12], 12'b0};
                    state <= 2;
                    //instr_addr <= instr_addr + 4; 
                end
                7'b1101111:begin //JAL
                    type <= 40;
                    state <= 4;
                    //instr_addr <= instr_addr + 4; 
                    Re[rd] <= instr_addr;
                    instr_addr <= instr_addr - 4 + {11'b0  , Instruction[31] , Instruction[19:12] , Instruction[20] , Instruction[30:21] , 1'b0};
                end
            endcase
        end
        else if (state == 4) begin
            state <= 2;
        end
        else if(state == 5)begin
            state <= 6;
        end
        else if (state == 6) begin
            state <= 2;
            case(type)
            7'd14:begin //LW
                Re[rd] <= data_out;
            end
            7'd15:begin //LB
                Re[rd] <= { {24{data_out[7]}} , data_out[7:0]};
            end
            7'd16:begin //LH
                Re[rd] <= { {16{data_out[15]}} , data_out[15:0]};
            end
            7'd17:begin //LBU
                Re[rd] <= {24'b0 , data_out[7:0]};
            end
            7'd18:begin //LHU
                Re[rd] <= {16'b0 , data_out[15:0]};
            end
            endcase
        end
    end
end
endmodule