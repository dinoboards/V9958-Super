package custom_timings;
  function [9:0] CLOCKS_PER_HALF_LINE;
    input PAL_MODE;
    begin
      if (PAL_MODE) CLOCKS_PER_HALF_LINE = 864;  // Return this value if PAL_MODE is set
      else CLOCKS_PER_HALF_LINE = 858;  // Return this value if PAL_MODE is not set
    end
  endfunction

  function [9:0] FRAME_HEIGHT;
    input PAL_MODE;
    begin
      if (PAL_MODE) FRAME_HEIGHT = 625;  // Return this value if PAL_MODE is set
      else FRAME_HEIGHT = 525;  // Return this value if PAL_MODE is not set
    end
  endfunction

endpackage
