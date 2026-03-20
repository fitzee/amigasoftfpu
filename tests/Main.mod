MODULE Main;

(* Desktop test harness for the FPU co-processor.
   Injects commands via the stub bus driver and checks results. *)

FROM InOut IMPORT WriteString, WriteInt, WriteCard, WriteLn;
FROM FPUBus IMPORT Init, Poll, GetOpCount;
FROM FPUProto IMPORT
  CmdAdd, CmdSub, CmdMul, CmdDiv, CmdSqrt, CmdNeg, CmdAbs,
  CmdCmp, CmdI2F, CmdF2I, CmdPing,
  StReady, StNaN, StInf, StZero, StNeg,
  ProtoVersion;
FROM FloatBits IMPORT RealToBits, BitsToReal;
FROM Inject IMPORT bus_inject_cmd, bus_get_result, bus_get_status, bus_clear_cmd;

VAR
  pass, fail: INTEGER;

PROCEDURE Check(name: ARRAY OF CHAR; gotBits, expectBits: CARDINAL);
BEGIN
  IF gotBits = expectBits THEN
    INC(pass)
  ELSE
    WriteString("  FAIL: ");
    WriteString(name);
    WriteString(" (got=");
    WriteCard(gotBits, 1);
    WriteString(" expect=");
    WriteCard(expectBits, 1);
    WriteString(")");
    WriteLn;
    INC(fail)
  END
END Check;

PROCEDURE StatusOK(name: ARRAY OF CHAR; gotStatus: INTEGER);
BEGIN
  IF CARDINAL(gotStatus) >= StReady THEN
    INC(pass)
  ELSE
    WriteString("  FAIL: ");
    WriteString(name);
    WriteString(" not ready");
    WriteLn;
    INC(fail)
  END
END StatusOK;

PROCEDURE RunCmd(cmd: INTEGER; a, b: CARDINAL);
BEGIN
  bus_inject_cmd(cmd, a, b);
  Poll
END RunCmd;

PROCEDURE TestArithmetic;
VAR r: CARDINAL; s: INTEGER;
BEGIN
  WriteString("--- Arithmetic ---"); WriteLn;

  RunCmd(CmdAdd, RealToBits(1.0), RealToBits(2.0));
  r := bus_get_result(); s := bus_get_status();
  Check("1.0 + 2.0 = 3.0", r, RealToBits(3.0));
  bus_clear_cmd;

  RunCmd(CmdSub, RealToBits(5.0), RealToBits(2.0));
  r := bus_get_result();
  Check("5.0 - 2.0 = 3.0", r, RealToBits(3.0));
  bus_clear_cmd;

  RunCmd(CmdMul, RealToBits(3.0), RealToBits(4.0));
  r := bus_get_result();
  Check("3.0 * 4.0 = 12.0", r, RealToBits(12.0));
  bus_clear_cmd;

  RunCmd(CmdDiv, RealToBits(10.0), RealToBits(4.0));
  r := bus_get_result();
  Check("10.0 / 4.0 = 2.5", r, RealToBits(2.5));
  bus_clear_cmd;

  RunCmd(CmdSqrt, RealToBits(4.0), 0);
  r := bus_get_result();
  Check("sqrt(4.0) = 2.0", r, RealToBits(2.0));
  bus_clear_cmd;

  RunCmd(CmdNeg, RealToBits(3.0), 0);
  r := bus_get_result();
  Check("neg(3.0) = -3.0", r, RealToBits(-3.0));
  bus_clear_cmd;

  RunCmd(CmdAbs, RealToBits(-7.0), 0);
  r := bus_get_result();
  Check("abs(-7.0) = 7.0", r, RealToBits(7.0));
  bus_clear_cmd
END TestArithmetic;

PROCEDURE TestConversions;
VAR r: CARDINAL;
BEGIN
  WriteString("--- Conversions ---"); WriteLn;

  RunCmd(CmdI2F, CARDINAL(42), 0);
  r := bus_get_result();
  Check("i2f(42) = 42.0", r, RealToBits(42.0));
  bus_clear_cmd;

  RunCmd(CmdF2I, RealToBits(7.9), 0);
  r := bus_get_result();
  Check("f2i(7.9) = 7", r, 7);
  bus_clear_cmd
END TestConversions;

PROCEDURE TestSpecial;
VAR r: CARDINAL; s: INTEGER;
BEGIN
  WriteString("--- Special values ---"); WriteLn;

  (* 0/0 = NaN *)
  RunCmd(CmdDiv, RealToBits(0.0), RealToBits(0.0));
  s := bus_get_status();
  Check("0/0 status has NaN", CARDINAL(s) DIV StNaN MOD 2, 1);
  bus_clear_cmd;

  (* sqrt(-1) = NaN *)
  RunCmd(CmdSqrt, RealToBits(-1.0), 0);
  s := bus_get_status();
  Check("sqrt(-1) status has NaN", CARDINAL(s) DIV StNaN MOD 2, 1);
  bus_clear_cmd;

  (* Ping *)
  RunCmd(CmdPing, 0, 0);
  r := bus_get_result();
  Check("ping = version", r, ProtoVersion);
  bus_clear_cmd
END TestSpecial;

BEGIN
  pass := 0;
  fail := 0;

  WriteString("Amiga FPU co-processor test harness"); WriteLn;
  WriteLn;

  Init;

  TestArithmetic;
  TestConversions;
  TestSpecial;

  WriteLn;
  WriteString("=== ");
  WriteInt(pass, 1);
  WriteString(" passed, ");
  WriteInt(fail, 1);
  WriteString(" failed, ");
  WriteInt(INTEGER(GetOpCount()), 1);
  WriteString(" ops dispatched ===");
  WriteLn;

  IF fail # 0 THEN HALT END
END Main.
