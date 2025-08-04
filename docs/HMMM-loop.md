## Analysis of state machine in command for HMMM

#### IDLE:

#### CHK_LOOP:

```
1.  IF <finished> THEN NEXT EXEC_END

2.  IF <finished row> THEN increment dest Y and source Y
```

#### RD_VRAM:

```
1.  set x and y to source

2.  // initiate request to read the source byte
    vram_rd_req <= ~vram_rd_ack
```

#### WAIT_RD_VRAM:

```
1.  // wait until the dest byte is read
    IF vram_rd_req != vram_rd_ack THEN NEXT WAIT_RD_VRAM

2.  // load the source byte into the wr byte
    vram_wr_data_8 <= RDPOINT(vram_rd_data)
```

#### WR_VRAM:

```
1.  set x and y to dest

    // initiate request to write the byte
2.  internal_vram_wr_req <= ~vram_wr_ack
```

#### WAIT_WR_VRAM:

```

1.  //wait until the new
    IF internal_vram_wr_req != vram_wr_ack THEN NEXT WAIT_WR_VRAM dest byte is written

2.  increment dx

3.  decrement nx

4.  NEXT CHK_LOOP
```
