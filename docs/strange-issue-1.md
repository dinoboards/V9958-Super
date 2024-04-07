
## Strange Issue 1:

### vdp_super code somehow corrupting non vdp_super mode screen output

In (src/vdp/vdp_super_res.sv)[src/vdp/vdp_super_res.sv] there is code to increment the vram address for rendering in `vdp_super` mode:

```
  if (active_line) begin
    super_res_vram_addr <= 17'(super_res_vram_addr + 4);
  end
```

The above code, increments 4 bytes for the `super_color` mode.  The plan is to change the incrementing value for `super_mid` and `super_res`.  (2 for `super_mid` and 1 for `super_color`)

So far so good.

There is related code in (src/vdp/address_bus.sv)[src/vdp/address_bus.sv]:

```
  if (vdp_super) begin
    IRAMADR <= super_vram_addr;
    PRAMDBO_8 <= 8'bZ;
    PRAMDBO_32 <= 32'bZ;
    PRAMWE_N <= 1'b1;
    PRAM_RD_SIZE <= `MEMORY_WIDTH_32;

  end else begin
```

The code above, is only activated when `vdp_super` is active, and will load the rendering vram byte address to the memory controller.

The `vdp_super` state does not activate until the register 31 is written to.  So in boot up, its initialised at 0.

This is proven, by adding a test point in the above code, to confirm the `vdp_super` block is never encountered until the register is explicitly updated by running a program to set the register.

Yet, if I change the vram address increment from 4 to 2, as below.  The screen image on boot up goes becomes a solid white colour.  That is, by changing the incrementing value, we somehow impacted normal screen modes (including the boot mode)

```
  if (active_line) begin
    super_res_vram_addr <= 17'(super_res_vram_addr + 2);
  end
```

If in (src/vdp/address_bus.sv)[src/vdp/address_bus.sv], I then comment out the address loading (which should not be happening since we are never in `vdp_super` mode), the normal screen modes work again.

```
  if (vdp_super) begin
    //IRAMADR <= super_vram_addr;
    PRAMDBO_8 <= 8'bZ;
    PRAMDBO_32 <= 32'bZ;
    PRAMWE_N <= 1'b1;
    PRAM_RD_SIZE <= `MEMORY_WIDTH_32;

  end else begin
```

#### Unknowns:

How can a state that is never encountered, somehow impact the operation?  Why does changing a vram address increment from 4 to 2 do this.

I have also confirmed, that the code to increment the address is also never encountered.  So its not even incrementing the address.

### Additional

There are 2 places where vram address is incremented.  Once at during the last line, and once at the end of each line.

As the vram address is set to 0 at the start of the last line.  Later on, during the last line, the first increment is applied.

## Observations

With the (src/vdp/vdp_super_res.sv)[src/vdp/vdp_super_res.sv]:
1. If the 2 vram increments are 4, then everything works as expected.
2. if the 2 vram increments are 2, then normal mode is corrupted.
3. if the first increment is 2 and the second increment is 4, then everything works as expected.
4. if the first increment is 4 and the second increment is 2, then everything works as expected.
5. if the first increment is changed to an explicit assignment (=2), then everything seems to work as expected.


Is there some optimisation issue with the synthesizer and layout?  Does it corrupt something, when I have 2 increments applied to vram at 2 distinct states?

## Worked Around

1. By having the first increment and absolute assignment, and not using trinary operator and instead explicit conditions - the underlying problem seems to have been resolved.  Except, when I removed the diagnostic LEDs from the circuit, the issue comes back.

2. Change place_option and route_option from 1 to 0 (0 being default) in tcl config:

```
set_option -place_option 0
set_option -route_option 0
```

  I do wonder if these settings had been the cause all along.

## Further Observations (2023-04-04)

The above issue was never resolved with changing optimisation strategies.  Some further observations have been noted.

Have enabled the reporting options in the tcl file.

In the project.tr file, we get entries like:

```
2. Timing Summaries
2.1 STA Tool Run Summary
<Setup Delay Model>:Slow 0.95V 85C C8/I7
<Hold Delay Model>:Fast 1.05V 0C C8/I7
<Numbers of Paths Analyzed>:19282
<Numbers of Endpoints Analyzed>:7809
<Numbers of Falling Endpoints>:0
<Numbers of Setup Violated Endpoints>:756
<Numbers of Hold Violated Endpoints>:18
```

I noticed that the `hdmi_reset` signal seemed to be appearing a lot - its not a buffered signals, yet was required for a lot of always_ff blocks.  Removing the use of this signal - and just using `reset_w`, the number of Setup and Hold violations greatly reduced. And the problem seems to possibly happen a lot less.  (I don't think we need a specific `hdmi_reset` signal - seems to work fine just running off the main `reset_w` signal)

I also changed sdram/memory_controller modules, to have separate FF for out32 and out16 registers.  Hoping that it enables better routing and avoid congestion/fanout issues.  This change also did seem to reduce the issue.

Perhaps the other violations need to be 'resolved'

Only conducted a limited set of testing (main video mode, super modes).  There may be issues with sprites, other graphic modes and other timing issues the intermittently cause issues.

## Further Observations (2023-04-07)

Resolved a lot of hold/setup timing violations.  Some between the `SSG` and `ADDRESS_BUS` to `SDRAM` have been 'ignored'. All others have been 'fixed.

The `SDRAM` signals are all cross clock domains (the main 27Mhz clk signal and the 108Mhz sdram clocks).

> I think the reported issues the `SDRAM` timing are effectively avoided, as the read/write operations are controlled by the `DOTSTATE`.  This will cause the read and writes to be synchronised with double flip-flop operations.  And I can only guess the analyser is not able to take this in to consideration when reporting.  It perhaps might be required to have the data flowing from and into the SDRAM implemented more clearly with the double flip-flops.
