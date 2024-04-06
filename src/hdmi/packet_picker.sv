// Implementation of HDMI packet choice logic.
// By Sameer Puri https://github.com/sameer

module PACKET_PICKER #(
    parameter int VIDEO_ID_CODE = 4,
    parameter longint VIDEO_RATE = 0,
    parameter bit IT_CONTENT = 1'b0,
    parameter int AUDIO_BIT_WIDTH = 0,
    parameter int AUDIO_RATE = 0,
    parameter bit [8*8-1:0] VENDOR_NAME = 0,
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = 0,
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 0
) (
    input logic clk_pixel,
    input logic clk_audio,
    input logic reset,
    input logic video_field_end,
    input logic packet_enable,
    input logic [4:0] packet_pixel_counter,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word[1:0],
    output logic [23:0] header,
    output logic [55:0] sub[3:0]
);

  typedef enum logic [2:0] {
    /* 0x00 */ NULL_PACKET,
    /* 0x01 */ AUDIO_CLOCK_REGENERATION_PACKET,
    /* 0x02 */ AUDIO_SAMPLE_PACKET,
    /* 0x82 */ AVI_INFO_FRAME,
    /* 0x83 */ SOURCE_PRODUCT_DESCRIPTION_INFO_FRAME,
    /* 0x84 */ AUDIO_INFO_FRAME
  } PACKET_TYPES;

  PACKET_TYPES packet_type;

  logic [23:0] null_header;
  logic [23:0] audio_clock_regeneration_header;
  logic [23:0] audio_sample_header;
  logic [23:0] avi_info_frame_header;
  logic [23:0] source_product_description_info_frame_header;
  logic [23:0] audio_info_frame_header;

  logic [55:0] null_sub[3:0];
  logic [55:0] audio_clock_regeneration_sub[3:0];
  logic [55:0] audio_sample_sub[3:0];
  logic [55:0] avi_info_frame_sub[3:0];
  logic [55:0] source_product_description_info_frame_sub[3:0];
  logic [55:0] audio_info_frame_sub[3:0];

  always_comb begin
    case (packet_type)
      NULL_PACKET: header = null_header;
      AUDIO_CLOCK_REGENERATION_PACKET: header = audio_clock_regeneration_header;
      AUDIO_SAMPLE_PACKET: header = audio_sample_header;
      AVI_INFO_FRAME: header = avi_info_frame_header;
      SOURCE_PRODUCT_DESCRIPTION_INFO_FRAME: header = source_product_description_info_frame_header;
      AUDIO_INFO_FRAME: header = audio_info_frame_header;
      default: header = null_header;
    endcase
  end

  always_comb begin
    case (packet_type)
      NULL_PACKET: sub = null_sub;
      AUDIO_CLOCK_REGENERATION_PACKET: sub = audio_clock_regeneration_sub;
      AUDIO_SAMPLE_PACKET: sub = audio_sample_sub;
      AVI_INFO_FRAME: sub = avi_info_frame_sub;
      SOURCE_PRODUCT_DESCRIPTION_INFO_FRAME: sub = source_product_description_info_frame_sub;
      AUDIO_INFO_FRAME: sub = audio_info_frame_sub;
      default: sub = null_sub;
    endcase
  end

  // "An HDMI Sink shall ignore bytes HB1 and HB2 of the Null Packet Header and all bytes of the Null Packet Body."
  assign null_header = {8'dX, 8'dX, 8'd0};
  assign null_sub[0] = 56'dX;
  assign null_sub[1] = 56'dX;
  assign null_sub[2] = 56'dX;
  assign null_sub[3] = 56'dX;

  logic clk_audio_counter_wrap;
  AUDIO_CLOCK_REGENERATION_PACKET #(
      .VIDEO_RATE(VIDEO_RATE),
      .AUDIO_RATE(AUDIO_RATE)
  ) audio_clock_regeneration_packet (
      .clk_pixel(clk_pixel),
      .clk_audio(clk_audio),
      .clk_audio_counter_wrap(clk_audio_counter_wrap),
      .header(audio_clock_regeneration_header),
      .sub(audio_clock_regeneration_sub)
  );

  // Audio Sample packet
  localparam bit [3:0] SAMPLING_FREQUENCY = AUDIO_RATE == 32000 ? 4'b0011
    : AUDIO_RATE == 44100 ? 4'b0000
    : AUDIO_RATE == 88200 ? 4'b1000
    : AUDIO_RATE == 176400 ? 4'b1100
    : AUDIO_RATE == 48000 ? 4'b0010
    : AUDIO_RATE == 96000 ? 4'b1010
    : AUDIO_RATE == 192000 ? 4'b1110
    : 4'bXXXX;
  localparam int AUDIO_BIT_WIDTH_COMPARATOR = AUDIO_BIT_WIDTH < 20 ? 20 : AUDIO_BIT_WIDTH == 20 ? 25 : AUDIO_BIT_WIDTH < 24 ? 24 : AUDIO_BIT_WIDTH == 24 ? 29 : -1;
  localparam bit [2:0] WORD_LENGTH = 3'(AUDIO_BIT_WIDTH_COMPARATOR - AUDIO_BIT_WIDTH);
  localparam bit WORD_LENGTH_LIMIT = AUDIO_BIT_WIDTH <= 20 ? 1'b0 : 1'b1;

  logic audio_sample_word_transfer_control = 1'd0;
  logic audio_sample_word_transfer_control_sync1, audio_sample_word_transfer_control_sync2;

  always_ff @(posedge clk_audio) begin
    audio_sample_word_transfer_control <= !audio_sample_word_transfer_control;
  end

  always_ff @(posedge clk_pixel) begin
    audio_sample_word_transfer_control_sync1 <= audio_sample_word_transfer_control;
    audio_sample_word_transfer_control_sync2 <= audio_sample_word_transfer_control_sync1;
  end

  logic [1:0] audio_sample_word_transfer_control_synchronizer_chain = 2'd0;
  always_ff @(posedge clk_pixel) begin
    audio_sample_word_transfer_control_synchronizer_chain <= {audio_sample_word_transfer_control_sync2, audio_sample_word_transfer_control_synchronizer_chain[1]};
  end

  logic sample_buffer_current = 1'b0;
  logic [1:0] samples_remaining = 2'd0;
  logic [23:0] audio_sample_word_buffer[1:0][3:0][1:0];
  logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_transfer_mux[1:0];
  always_comb begin
    if (audio_sample_word_transfer_control_synchronizer_chain[0] ^ audio_sample_word_transfer_control_synchronizer_chain[1]) audio_sample_word_transfer_mux = audio_sample_word;
    else
      audio_sample_word_transfer_mux = '{
          audio_sample_word_buffer[sample_buffer_current][samples_remaining][1][23:(24-AUDIO_BIT_WIDTH)],
          audio_sample_word_buffer[sample_buffer_current][samples_remaining][0][23:(24-AUDIO_BIT_WIDTH)]
      };
  end

  logic sample_buffer_used = 1'b0;
  logic sample_buffer_ready = 1'b0;

  always_ff @(posedge clk_pixel) begin
    if (sample_buffer_used) sample_buffer_ready <= 1'b0;

    if (audio_sample_word_transfer_control_synchronizer_chain[0] ^ audio_sample_word_transfer_control_synchronizer_chain[1]) begin
      audio_sample_word_buffer[sample_buffer_current][samples_remaining][0] <= 24'(audio_sample_word_transfer_mux[0]) << (24 - AUDIO_BIT_WIDTH);
      audio_sample_word_buffer[sample_buffer_current][samples_remaining][1] <= 24'(audio_sample_word_transfer_mux[1]) << (24 - AUDIO_BIT_WIDTH);
      if (samples_remaining == 2'd3) begin
        samples_remaining <= 2'd0;
        sample_buffer_ready <= 1'b1;
        sample_buffer_current <= !sample_buffer_current;
      end else samples_remaining <= samples_remaining + 1'd1;
    end
  end

  logic [23:0] audio_sample_word_packet[3:0][1:0];
  logic [3:0] audio_sample_word_present_packet;

  logic [7:0] frame_counter = 8'd0;
  int k;
  always_ff @(posedge clk_pixel) begin
    if (reset) begin
      frame_counter <= 8'd0;
    end
    else if (packet_pixel_counter == 5'd31 && packet_type == AUDIO_SAMPLE_PACKET) // Keep track of current IEC 60958 frame
    begin
      frame_counter = frame_counter + 8'd4;
      if (frame_counter >= 8'd192) frame_counter = frame_counter - 8'd192;
    end
  end

  AUDIO_SAMPLE_PACKET #(
      .SAMPLING_FREQUENCY(SAMPLING_FREQUENCY),
      .WORD_LENGTH({{WORD_LENGTH[0], WORD_LENGTH[1], WORD_LENGTH[2]}, WORD_LENGTH_LIMIT})
  ) audio_sample_packet (
      .frame_counter(frame_counter),
      .valid_bit('{2'b00, 2'b00, 2'b00, 2'b00}),
      .user_data_bit('{2'b00, 2'b00, 2'b00, 2'b00}),
      .audio_sample_word(audio_sample_word_packet),
      .audio_sample_word_present(audio_sample_word_present_packet),
      .header(audio_sample_header),
      .sub(audio_sample_sub)
  );

  AUXILIARY_VIDEO_INFORMATION_INFO_FRAME #(
      .VIDEO_ID_CODE(7'(VIDEO_ID_CODE)),
      .IT_CONTENT(IT_CONTENT)
  ) auxiliary_video_information_info_frame (
      .header(avi_info_frame_header),
      .sub(avi_info_frame_sub)
  );

  SOURCE_PRODUCT_DESCRIPTION_INFO_FRAME #(
      .VENDOR_NAME(VENDOR_NAME),
      .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
      .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
  ) source_product_description_info_frame (
      .header(source_product_description_info_frame_header),
      .sub(source_product_description_info_frame_sub)
  );

  AUDIO_INFO_FRAME audio_info_frame (
      .header(audio_info_frame_header),
      .sub(audio_info_frame_sub)
  );

  // "A Source shall always transmit... [an InfoFrame] at least once per two Video Fields"
  logic audio_info_frame_sent = 1'b0;
  logic auxiliary_video_information_info_frame_sent = 1'b0;
  logic source_product_description_info_frame_sent = 1'b0;
  logic last_clk_audio_counter_wrap = 1'b0;

  always_ff @(posedge clk_pixel) begin
    if (sample_buffer_used) sample_buffer_used <= 1'b0;

    if (reset || video_field_end) begin
      audio_info_frame_sent <= 1'b0;
      auxiliary_video_information_info_frame_sent <= 1'b0;
      source_product_description_info_frame_sent <= 1'b0;
      packet_type <= NULL_PACKET;
    end else if (packet_enable) begin
      if (last_clk_audio_counter_wrap ^ clk_audio_counter_wrap) begin
        packet_type <= AUDIO_CLOCK_REGENERATION_PACKET;
        last_clk_audio_counter_wrap <= clk_audio_counter_wrap;
      end else if (sample_buffer_ready) begin
        packet_type <= AUDIO_SAMPLE_PACKET;
        audio_sample_word_packet <= audio_sample_word_buffer[!sample_buffer_current];
        audio_sample_word_present_packet <= 4'b1111;
        sample_buffer_used <= 1'b1;
      end else if (!audio_info_frame_sent) begin
        packet_type <= AUDIO_INFO_FRAME;
        audio_info_frame_sent <= 1'b1;
      end else if (!auxiliary_video_information_info_frame_sent) begin
        packet_type <= AVI_INFO_FRAME;
        auxiliary_video_information_info_frame_sent <= 1'b1;
      end else if (!source_product_description_info_frame_sent) begin
        packet_type <= SOURCE_PRODUCT_DESCRIPTION_INFO_FRAME;
        source_product_description_info_frame_sent <= 1'b1;
      end else packet_type <= NULL_PACKET;
    end
  end

endmodule
