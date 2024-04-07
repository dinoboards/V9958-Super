## Single or double Multiplication

The two assignments noted below, although the calculate to the same result, are allocated different resources and generate different propagation delays

By multiplying by 720, then adding a value, GOWIN's synthesis will use the `MULT18X18` DSP, then construct a lot of combinational logic for the add.

```
assign vram_access_addr2 = 18'((vram_access_y * 720) + (vram_access_x * 2));
```


Compared to implementing the assignment as follows:

```
assign vram_access_addr2 = 18'((vram_access_y * 360*2) + (vram_access_x * 2));
```

Here, GOWIN's synthesis will use use a DSP of `MULTADDALU18X18` to perform both the multiplication and add in one unit.  Resulting in a lower propagation compared to the previous assignment

I can not see a way to 'encourage' GOWIN's synthesis to produce the more optimal resource usage with the single multiplication.
