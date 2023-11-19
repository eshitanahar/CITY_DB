CREATE OR REPLACE FUNCTION EMOB."DFN_SPELL_NUMBER" (
   i_numtyp     IN   VARCHAR2,
   i_amount     IN   NUMBER,
   i_basecurr   IN   VARCHAR2,
   i_subcurr    IN   VARCHAR2
)
   RETURN VARCHAR2
IS
   t_amount     NUMBER;
   t_decimal    NUMBER;
   t_intwords   VARCHAR2 (2000);
   t_decwords   VARCHAR2 (2000);
   numtyp       CHAR (1)        := UPPER (i_numtyp);
BEGIN
   IF numtyp NOT IN ('A', 'M')
   THEN
      raise_application_error (-20010,
                               'Invalid Type, Valid Values are [A/M]');
   END IF;

   IF i_numtyp = 'A'
   THEN
      RETURN dfn_spell_number_in_arabian (i_amount,
                                          INITCAP (i_basecurr),
                                          INITCAP (i_subcurr)
                                         );
   --return dfn_spell_number_in_arabian(i_amount,initcap(i_basecurr),initcap(i_subcurr))||' Only';
   ELSE
      t_amount := FLOOR (i_amount);
      t_decimal := ((i_amount * 100) - (FLOOR (i_amount) * 100));

      IF t_amount > 0
      THEN
         --T_Intwords := initcap(i_basecurr)||':  '||dfn_spell_number_in_metric(i_amount)||'Only';
         --T_Intwords := initcap(i_basecurr)||':  '||dfn_spell_number_in_metric(i_amount);
         t_intwords :=
               INITCAP (i_basecurr)
            || ' '
            || dfn_spell_number_in_metric (i_amount);
      END IF;

      IF t_decimal > 0
      THEN
         t_decwords :=
               ' And '
            || dfn_spell_number_in_metric (t_decimal)
            || ' '
            ||
               --initcap(i_subcurr)||' '||'Only';
               INITCAP (i_subcurr);
      END IF;

      RETURN t_intwords || t_decwords;
   END IF;
END;
/
