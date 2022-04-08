set serveroutput on;
-- creation of the tictacgridOX table if it does not exist
DECLARE
  numbox NUMBER;
BEGIN
  SELECT count(*) INTO numbox FROM user_tables 
    WHERE TABLE_NAME = 'gridOX';
  IF numbox = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE gridOX(
      y NUMBER,
      A CHAR,
      B CHAR,
      C CHAR
    )';
 END IF;
END;
/
-- procedure to display the board
CREATE OR REPLACE PROCEDURE print_game IS
BEGIN
  dbms_output.enable(10000);
  dbms_output.put_line(' ');
  FOR ll in (SELECT * FROM gridOX ORDER BY Y) LOOP
    dbms_output.put_line('     ' || ll.A || ' ' || ll.B || ' ' || ll.C);
  END LOOP; 
  dbms_output.put_line(' ');
END;
/
-- function for converting column number to column name
CREATE OR REPLACE FUNCTION nbToColName(col IN NUMBER)
RETURN CHAR
IS
BEGIN
  IF col=1 THEN
    RETURN 'A';
  ELSIF col=2 THEN
    RETURN 'B';
  ELSIF col=3 THEN
    RETURN 'C';
  ELSE 
    RETURN '_';
  END IF;
END;
/
-- procedure to play the game
CREATE OR REPLACE PROCEDURE play(symbol IN VARCHAR2, rownm IN NUMBER, colnum IN NUMBER) IS
val gridOX.a%type;
colo CHAR;
symbol2 CHAR;
BEGIN
  SELECT nbToColName(colnum) INTO colo FROM DUAL;
  EXECUTE IMMEDIATE ('SELECT ' || colo || ' FROM gridOX WHERE y=' || rownm) INTO val;
  IF val='_' THEN
    EXECUTE IMMEDIATE ('UPDATE gridOX SET ' || colo || '=''' || symbol || ''' WHERE y=' || rownm);
    IF symbol='X' THEN
      symbol2:='O';
    ELSE
      symbol2:='X';
    END IF;
    print_game();
    dbms_output.put_line('Turn ' || symbol2 || '. To play : EXECUTE play(''' || symbol2 || ''', x, y);');
  ELSE
    dbms_output.enable(10000);
    dbms_output.put_line('Square already occupied. Cannot do this move.');
  END IF;
END;
/
-- procedure to reset the game
CREATE OR REPLACE PROCEDURE reset_game IS
ii NUMBER;
BEGIN
  DELETE FROM gridOX;
  FOR ii in 1..3 LOOP
    INSERT INTO gridOX VALUES (ii,'_','_','_');
  END LOOP; 
  dbms_output.enable(10000);
  print_game();
  dbms_output.put_line('Ready to play : EXECUTE play(''X'', x, y);');
END;
/
-- procedure win condition
CREATE OR REPLACE PROCEDURE winner(symbol IN VARCHAR2) IS
BEGIN
  dbms_output.enable(10000);
  print_game();
  dbms_output.put_line('The player ' || symbol || ' won!!'); 
  dbms_output.put_line('---------------------------------------');
  dbms_output.put_line('Starting a new game...');
  reset_game();
END;
/
-- function for column query
CREATE OR REPLACE FUNCTION winloop_req(colnum IN VARCHAR2, symbol IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
  RETURN ('SELECT COUNT(*) FROM gridOX WHERE ' || colnum || ' = '''|| symbol ||''' AND ' || colnum || ' != ''_''');
END;
/
-- function for column query
CREATE OR REPLACE FUNCTION wincross_request(colnum IN VARCHAR2, yvalue IN NUMBER)
RETURN VARCHAR2
IS
BEGIN
  RETURN ('SELECT '|| colnum ||' FROM gridOX WHERE y=' || yvalue);
END;
/
-- function for checking diagonal win
CREATE OR REPLACE FUNCTION wincross(tmpx IN CHAR, colnum IN NUMBER, rownm IN NUMBER)
RETURN CHAR
IS
  tmpvar CHAR;
  tmpxvar CHAR;
  r VARCHAR2(56);
BEGIN
  SELECT wincross_request(nbToColName(colnum), rownm) INTO r FROM DUAL;
  IF tmpx IS NULL THEN
    EXECUTE IMMEDIATE (r) INTO tmpxvar;
  ELSIF NOT tmpx = '_' THEN
    EXECUTE IMMEDIATE (r) INTO tmpvar;
    IF NOT tmpx = tmpvar THEN
      tmpxvar := '_';
    END IF;
  ELSE
    tmpxvar := '_';
  END IF;
  RETURN tmpxvar;
END;
/
-- function for checking column win
CREATE OR REPLACE FUNCTION wincol(colnum IN VARCHAR2)
RETURN CHAR
IS
  numwin NUMBER;
  r VARCHAR2(56);
BEGIN
  SELECT winloop_req(colnum, 'X') into r FROM DUAL;
  EXECUTE IMMEDIATE r INTO numwin;
  IF numwin=3 THEN
    RETURN 'X';
  ELSIF numwin=0 THEN
    SELECT winloop_req(colnum, 'O') into r FROM DUAL;
    EXECUTE IMMEDIATE r INTO numwin;
    IF numwin=3 THEN
      RETURN 'O';
    END IF;
  END IF;
  RETURN '_';
END;
/
-- Trigger for checking win condition
CREATE OR REPLACE TRIGGER checkwin
AFTER UPDATE ON gridOX
DECLARE
  CURSOR row_cr IS 
    SELECT * FROM gridOX ORDER BY Y; 
  box gridOX%rowtype;
  tmpvar CHAR;
  tmpx1 CHAR;
  tmpx2 CHAR;
  r VARCHAR2(40);
BEGIN
  FOR box IN row_cr LOOP
    -- row check win
    IF box.A = box.B AND box.B = box.C AND NOT box.A='_' THEN
      winner(box.A);
      EXIT;
    END IF;
    -- column check win
    SELECT wincol(nbToColName(box.Y)) INTO tmpvar FROM DUAL;
    IF NOT tmpvar = '_' THEN
      winner(tmpvar);
      EXIT;
    END IF;
    -- diagonal check win
    SELECT wincross(tmpx1, box.Y, box.Y) INTO tmpx1 FROM dual;
    SELECT wincross(tmpx2, 4-box.Y, box.Y) INTO tmpx2 FROM dual;
  END LOOP;
  IF NOT tmpx1 = '_' THEN
    winner(tmpx1);
  END IF;
  IF NOT tmpx2 = '_' THEN
    winner(tmpx2);
  END IF;
END;
/
--

EXECUTE reset_game;
EXECUTE play('X', 1, 3);
EXECUTE play('O', 2, 1);
EXECUTE play('X', 1, 1);
EXECUTE play('O', 2, 3);
EXECUTE play('X', 3, 3);
EXECUTE play('O', 3, 1);
EXECUTE play('X', 1, 2);