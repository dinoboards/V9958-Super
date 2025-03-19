package custom_timings;
  function [9:0] CLOCKS_PER_HALF_LINE;
    input PAL_MODE;
    begin
      if (PAL_MODE) CLOCKS_PER_HALF_LINE = 864;
      else CLOCKS_PER_HALF_LINE = 858;
    end
  endfunction

  function [9:0] FRAME_WIDTH;
    input PAL_MODE;
    begin
      if (PAL_MODE) FRAME_WIDTH = 864;
      else FRAME_WIDTH = 858;
    end
  endfunction

  function [9:0] FRAME_HEIGHT;
    input PAL_MODE;
    begin
      if (PAL_MODE) FRAME_HEIGHT = 625;
      else FRAME_HEIGHT = 525;
    end
  endfunction

  function [9:0] PIXEL_WIDTH;
    PIXEL_WIDTH = 720;  // Both 50 and 60hz modes have the same pixel width
  endfunction

  function [9:0] PIXEL_HEIGHT;
    input PAL_MODE;
    begin
      if (PAL_MODE) PIXEL_HEIGHT = 576;
      else PIXEL_HEIGHT = 480;
    end
  endfunction

  function [9:0] ENABLE_DRAW_ACCESS_AT_Y;
    input PAL_MODE;
    begin
      if (PAL_MODE) ENABLE_DRAW_ACCESS_AT_Y = 620;
      else ENABLE_DRAW_ACCESS_AT_Y = 520;
    end
  endfunction

  function [9:0] DISABLE_DRAW_ACCESS_AT_Y;
    input PAL_MODE;
    begin
      if (PAL_MODE) DISABLE_DRAW_ACCESS_AT_Y = 576;
      else DISABLE_DRAW_ACCESS_AT_Y = 480;
    end
  endfunction


  function [9:0] ENABLE_DRAW_ACCESS_AT_X;
    input PAL_MODE;
    begin
      if (PAL_MODE) ENABLE_DRAW_ACCESS_AT_X = 859;
      else ENABLE_DRAW_ACCESS_AT_X = 853;
    end
  endfunction

  function [9:0] DISABLE_DRAW_ACCESS_AT_X;
    input PAL_MODE;
    begin
      if (PAL_MODE) DISABLE_DRAW_ACCESS_AT_X = 720;
      else DISABLE_DRAW_ACCESS_AT_X = 720;
    end
  endfunction

  `define MAX_PIXEL_WIDTH 720

endpackage
