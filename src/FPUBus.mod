IMPLEMENTATION MODULE FPUBus;

FROM FPUCore IMPORT Execute;
FROM FPUProto IMPORT RegCmd, RegArgAHi, RegArgALo,
                     RegArgBHi, RegArgBLo, RegResHi, RegResLo, RegStatus;
FROM BusBridge IMPORT bus_read_reg, bus_write_reg, bus_has_cmd, bus_init;

VAR
  opCount: CARDINAL;

PROCEDURE Init;
BEGIN
  opCount := 0;
  bus_init;
  bus_write_reg(RegStatus, 0);
  bus_write_reg(RegResHi, 0);
  bus_write_reg(RegResLo, 0)
END Init;

PROCEDURE Poll;
VAR
  cmd: CARDINAL;
  argAhi, argAlo, argBhi, argBlo: CARDINAL;
  argA, argB: CARDINAL;
  result, status: CARDINAL;
BEGIN
  IF bus_has_cmd() = 0 THEN RETURN END;

  cmd := CARDINAL(bus_read_reg(RegCmd));
  argAhi := CARDINAL(bus_read_reg(RegArgAHi));
  argAlo := CARDINAL(bus_read_reg(RegArgALo));
  argBhi := CARDINAL(bus_read_reg(RegArgBHi));
  argBlo := CARDINAL(bus_read_reg(RegArgBLo));

  (* Assemble 32-bit operands from 16-bit halves *)
  argA := argAhi * 10000H + argAlo;
  argB := argBhi * 10000H + argBlo;

  Execute(cmd, argA, argB, result, status);

  (* Post result *)
  bus_write_reg(RegResHi, INTEGER(result DIV 10000H));
  bus_write_reg(RegResLo, INTEGER(CARDINAL(BITSET(result) * BITSET(0FFFFH))));
  bus_write_reg(RegStatus, INTEGER(status));

  INC(opCount)
END Poll;

PROCEDURE GetOpCount(): CARDINAL;
BEGIN
  RETURN opCount
END GetOpCount;

END FPUBus.
