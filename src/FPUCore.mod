IMPLEMENTATION MODULE FPUCore;

FROM MathLib IMPORT sqrt;
FROM FloatBits IMPORT BitsToReal, RealToBits;
FROM RealMath IMPORT IsNaN, IsInf, IsNegZero, IsNegative;
FROM FPUProto IMPORT
  CmdNop, CmdAdd, CmdSub, CmdMul, CmdDiv, CmdSqrt,
  CmdNeg, CmdAbs, CmdCmp, CmdI2F, CmdF2I, CmdPing,
  StReady, StNaN, StInf, StZero, StNeg, StOvfl, StDivZ, StInval,
  ProtoVersion;

PROCEDURE Init;
BEGIN
  (* Nothing to init yet. SoftFloat32 init happens via module load. *)
END Init;

PROCEDURE MakeStatus(r: REAL): CARDINAL;
VAR s: CARDINAL;
BEGIN
  s := StReady;
  IF IsNaN(r) THEN s := s + StNaN END;
  IF IsInf(r) THEN s := s + StInf END;
  IF r = 0.0 THEN s := s + StZero END;
  IF IsNegative(r) THEN s := s + StNeg END;
  RETURN s
END MakeStatus;

PROCEDURE Execute(cmd: CARDINAL; argA, argB: CARDINAL;
                  VAR result: CARDINAL; VAR status: CARDINAL);
VAR
  a, b, r: REAL;
  cmpResult: INTEGER;
BEGIN
  a := BitsToReal(argA);
  b := BitsToReal(argB);
  r := 0.0;
  status := StReady;

  CASE cmd OF
    CmdNop:
      result := 0;
      RETURN |

    CmdAdd:
      r := a + b |

    CmdSub:
      r := a - b |

    CmdMul:
      r := a * b |

    CmdDiv:
      IF b = 0.0 THEN
        IF a = 0.0 THEN
          status := StReady + StInval + StNaN;
          result := 7FC00000H;  (* canonical NaN *)
          RETURN
        ELSE
          status := StReady + StDivZ + StInf;
          IF IsNegative(a) # IsNegative(b) THEN
            result := 0FF800000H  (* -Inf *)
          ELSE
            result := 7F800000H  (* +Inf *)
          END;
          RETURN
        END
      END;
      r := a / b |

    CmdSqrt:
      IF IsNegative(a) AND NOT IsNegZero(a) THEN
        status := StReady + StInval + StNaN;
        result := 7FC00000H;
        RETURN
      END;
      r := sqrt(a) |

    CmdNeg:
      r := -a |

    CmdAbs:
      IF a < 0.0 THEN r := -a ELSE r := a END |

    CmdCmp:
      IF IsNaN(a) OR IsNaN(b) THEN
        (* Unordered *)
        status := StReady + StInval;
        result := 7FC00000H;
        RETURN
      END;
      IF a < b THEN cmpResult := -1
      ELSIF a > b THEN cmpResult := 1
      ELSE cmpResult := 0
      END;
      result := CARDINAL(cmpResult);
      status := StReady;
      IF cmpResult = 0 THEN status := status + StZero END;
      IF cmpResult < 0 THEN status := status + StNeg END;
      RETURN |

    CmdI2F:
      r := FLOAT(INTEGER(argA)) |

    CmdF2I:
      IF IsNaN(a) OR IsInf(a) THEN
        status := StReady + StInval;
        result := 0;
        RETURN
      END;
      result := CARDINAL(TRUNC(a));
      status := StReady;
      RETURN |

    CmdPing:
      result := ProtoVersion;
      status := StReady;
      RETURN
  ELSE
    (* Unknown command *)
    status := StReady + StInval;
    result := 0;
    RETURN
  END;

  result := RealToBits(r);
  status := MakeStatus(r)
END Execute;

END FPUCore.
