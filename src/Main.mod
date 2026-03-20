MODULE Main;

(* Amiga FPU co-processor firmware.
   On ESP32: runs as main loop, polling the clockport bus.
   On desktop: runs test harness via injected commands. *)

FROM FPUBus IMPORT Init, Poll, GetOpCount;

BEGIN
  Init;
  LOOP
    Poll
  END
END Main.
