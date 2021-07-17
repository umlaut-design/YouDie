{ Some defines to compile the ZFS  -- Iv n Montes Velencoso (Dr.Slump)
  First version : 7-JAN-99
  Last update : 30-MAY-99
}

(* Define this to compile with IO errors messages support *)
{ DEFINE ZFS_ERRORMSGS}

(* Define this to use assembler where possible (faster)                    *)
(* If you experience some compilations faults try to undefine this         *)
{$DEFINE ZFS_ASSEMBLER}

(* Define this only to compile the ZFS SEEKING OPTIMIZER                   *)
{ DEFINE ZFS_SEEKING_INFO}


{$IFDEF ZFS_ASSEMBLER}
  {$ASMMODE INTEL}         {Use Intel assembler syntax}
{$ENDIF}
