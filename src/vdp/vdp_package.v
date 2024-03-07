package custom_timings;
  function [10:0] CLOCKS_PER_LINE;
    input PAL_MODE;
    begin
      if (PAL_MODE)
        CLOCKS_PER_LINE = 1728; // Return this value if PAL_MODE is set
      else
        CLOCKS_PER_LINE = 1716; // Return this value if PAL_MODE is not set
    end
  endfunction

  function [9:0] CLOCKS_PER_HALF_LINE;
    input PAL_MODE;
    begin
      if (PAL_MODE)
        CLOCKS_PER_HALF_LINE = 864; // Return this value if PAL_MODE is set
      else
        CLOCKS_PER_HALF_LINE = 858; // Return this value if PAL_MODE is not set
    end
  endfunction
endpackage
