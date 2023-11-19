CREATE OR REPLACE FUNCTION EMOB."DFN_FORMAT_NUMBER" 
(i_NumTyp in Varchar2,   i_NumLen  in Number,
i_NumDec in Number, i_mastyp in varchar2)
RETURN  Varchar2 IS
        Nformat Varchar2(100) := '';
        Dformat Varchar2(100) := '';
        i       Number := 1 ;
        j       Number := 2;
        mastyp  Char(1) := nvl(i_mastyp,'9');
Begin

   If i_NumTyp not in ('A','M') then
         Raise_application_error(-20010,'Invalid Type, Valid Values are [A/M]');
    End if;
    If mastyp not in ('9','N') then
         Raise_application_error(-20010,'Invalid Mask Type, Valid Values are [9/N]');
    End if;
   While  i <= i_NumLen
   Loop
          Exit When i > i_NumLen;

          If Length(Nformat) = j then
             if mastyp = '9' then
                Nformat    := ',9'||Nformat;
             else
                Nformat    := 'GN'||Nformat;
             end if;
                If i_NumTyp = 'M' then
                         j       := j + 4;
                Else
                         j       := j + 3;
                End if;
          Else
            if i <> 1 then
               if mastyp = '9' then
                  Nformat    := '9' || Nformat;
               Else
                  Nformat    := 'N' || Nformat;
               End if;
            else
                  Nformat    := '0' || Nformat;
            End if;
          End if;
          i := i + 1;
  End loop;

  if mastyp = '9' then
     If Substr(Nformat,1,1) = ',' then
         Nformat := Substr(Nformat,2,Length(Nformat));
     End if;
  else
     If Substr(Nformat,1,1) = 'G' then
         Nformat := Substr(Nformat,2,Length(Nformat));
     End if;

  End if;

  If i_NumDec is not null then
          i := 1;
          While i <= i_NumDec Loop
                Exit When i > i_NumDec;
                   Dformat := Dformat || '9';
                i := i + 1;
          End loop;
          If i_Numdec = 0 then
                 Nformat := Nformat;
          Else
             if mastyp = '9' then
                 Nformat := Nformat || '.' || Dformat;
             Else
                 Nformat := Nformat || 'D' || Dformat;
             End if;
          End If;
End if;
Return Nformat;
End;
/
