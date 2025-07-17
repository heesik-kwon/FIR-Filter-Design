`timescale 1ns/1ps

module rrc_filter_pipe #(
   parameter WIDTH = 7  // format: <1.6>
)(
   input clk,
   input rstn,
   input [WIDTH-1:0] data_in, 
   output logic signed [WIDTH-1:0] data_out
);

   // Shift Register
   logic signed [WIDTH-1:0] shift_din [32:0];
   //integer i;

   always_ff @(posedge clk or negedge rstn) begin
      integer i;
      if (~rstn) begin
         for(i=0; i<=32; i=i+1)
            shift_din[i] <= 0;
      end else begin
         for(i=32; i>0; i=i-1)
            shift_din[i] <= shift_din[i-1];
         shift_din[0] <= data_in;
      end
   end

   // Stage 1: Multipliers (signed): 곱셈 결과들을 레지스터에 저장, mul_pipe[i]는 플리플롭에 의해 클럭 상승엣지에서 샘플링됨
   // 즉, mul_pipe[i]는 곱셈 결과를 저장하는 레지스터(플리플롭), 곱셈 결과가 한 클럭 사이클 지연되며 다음 파이프라인 단계로 전달된다.
   logic signed [WIDTH+9-1:0] mul_pipe[32:0];

   always_ff @(posedge clk or negedge rstn) begin
      integer i;
      if (~rstn) begin
         for (i = 0; i <= 32; i = i + 1)
            mul_pipe[i] <= 0;
      end else begin
         mul_pipe[ 0] <= shift_din[ 0] * 0;
         mul_pipe[ 1] <= shift_din[ 1] * -1;
         mul_pipe[ 2] <= shift_din[ 2] * 1;
         mul_pipe[ 3] <= shift_din[ 3] * 0;
         mul_pipe[ 4] <= shift_din[ 4] * -1;
         mul_pipe[ 5] <= shift_din[ 5] * 2;
         mul_pipe[ 6] <= shift_din[ 6] * 0;
         mul_pipe[ 7] <= shift_din[ 7] * -2;
         mul_pipe[ 8] <= shift_din[ 8] * 2;
         mul_pipe[ 9] <= shift_din[ 9] * 0;
         mul_pipe[10] <= shift_din[10] * -6;
         mul_pipe[11] <= shift_din[11] * 8;
         mul_pipe[12] <= shift_din[12] * 10;
         mul_pipe[13] <= shift_din[13] * -28;
         mul_pipe[14] <= shift_din[14] * -14;
         mul_pipe[15] <= shift_din[15] * 111;
         mul_pipe[16] <= shift_din[16] * 196;
         mul_pipe[17] <= shift_din[17] * 111;
         mul_pipe[18] <= shift_din[18] * -14;
         mul_pipe[19] <= shift_din[19] * -28;
         mul_pipe[20] <= shift_din[20] * 10;
         mul_pipe[21] <= shift_din[21] * 8;
         mul_pipe[22] <= shift_din[22] * -6;
         mul_pipe[23] <= shift_din[23] * 0;
         mul_pipe[24] <= shift_din[24] * 2;
         mul_pipe[25] <= shift_din[25] * -2;
         mul_pipe[26] <= shift_din[26] * 0;
         mul_pipe[27] <= shift_din[27] * 2;
         mul_pipe[28] <= shift_din[28] * -1;
         mul_pipe[29] <= shift_din[29] * 0;
         mul_pipe[30] <= shift_din[30] * 1;
         mul_pipe[31] <= shift_din[31] * -1;
         mul_pipe[32] <= shift_din[32] * 0;
      end
   end

   // Stage 2: 일부 덧셈 수행, sum_stage2[i](또 다른 DFF)
   logic signed [WIDTH+11-1:0] sum_stage2 [3:0];

   always_ff @(posedge clk or negedge rstn) begin
      integer i;
      if (~rstn) begin
         for (i = 0; i < 4; i = i + 1)
            sum_stage2[i] <= 0;
      end else begin
         sum_stage2[0] <= mul_pipe[0] + mul_pipe[1] + mul_pipe[2] + mul_pipe[3] +
                          mul_pipe[4] + mul_pipe[5] + mul_pipe[6] + mul_pipe[7];

         sum_stage2[1] <= mul_pipe[8] + mul_pipe[9] + mul_pipe[10] + mul_pipe[11] +
                          mul_pipe[12] + mul_pipe[13] + mul_pipe[14] + mul_pipe[15];

         sum_stage2[2] <= mul_pipe[16] + mul_pipe[17] + mul_pipe[18] + mul_pipe[19] +
                          mul_pipe[20] + mul_pipe[21] + mul_pipe[22] + mul_pipe[23];

         sum_stage2[3] <= mul_pipe[24] + mul_pipe[25] + mul_pipe[26] + mul_pipe[27] +
                          mul_pipe[28] + mul_pipe[29] + mul_pipe[30] + mul_pipe[31] + mul_pipe[32];
      end
   end

   // Stage 3: Final Sum & Truncate 최종 덧셈 및 결과 처리, filter_sum(마지막 DFF)
   logic signed [WIDTH+16-1:0] filter_sum;
   assign filter_sum = sum_stage2[0] + sum_stage2[1] + sum_stage2[2] + sum_stage2[3];
   
   logic signed [WIDTH+8-1:0] trunc_filter_sum;
   assign trunc_filter_sum = filter_sum[WIDTH+16-1:8];  // >>8

   // Output Clipping (Saturation)
   always_ff @(posedge clk or negedge rstn) begin
      if (~rstn)
         data_out <= 0;
      else if (trunc_filter_sum >= 63)
         data_out <= 63;
      else if (trunc_filter_sum < -64)
         data_out <= -64;
      else
         data_out <= trunc_filter_sum[WIDTH-1:0];
   end

endmodule