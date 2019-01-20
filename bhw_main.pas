(*
  That program finds undifinded programs in FreePascal code (in 'input.txt') and writes their names into the 'output.txt'



  Author:
  Mikhail Firsov
  email: firsov-ms@yandex.ru 

*)

const
  INPUT_FILE_NAME = 'input.txt';
  OUTPUT_FILE_NAME = 'output.txt';


function IsNameChar(const _char: char): boolean;
begin
  IsNameChar := ((_char >= '0') and (_char <= '9')) or ((_char >= 'a') and (_char <= 'z')) or ((_char >= 'A') and (_char <= 'Z')) or (_char = '_') or (_char = '&');
end;

type
  TNames = array of string;

function GetIndexIn(const arr: TNames; const s: string): integer;
var
  index: integer;
begin
  index := 0;
  while (index < Length(arr)) and (arr[ index ] <> s) do
    Inc(index);
  if index = Length(arr) then
    GetIndexIn := -1
  else
    GetIndexIn := index;
end;

procedure SkipWord(const _word: string; var index: integer);
begin
  Inc(index, Length(_word));      
end;

procedure Skip(const _cont: string; var index: integer; const code: string);
begin
  while Pos(code[ index ], _cont) > 0 do
    Inc(index);
end;

function IsBigLetter(const c: char): boolean;
begin
  IsBigLetter := ((c >= 'A') and (c <= 'Z'));
end;

procedure AddName(var names: TNames; name: string);
var
  index: integer;
begin
  SetLength(names, Length(names) + 1);
  for index := 1 to Length(name) do
    if IsBigLetter(name[ index ]) then
      name[ index ] := Copy('qwertyuiopasdfghjklzxcvbnm', Pos(name[ index ], 'QWERTYUIOPASDFGHJKLZXCVBNM'), 1)[ 1 ];
  names[ Length(names) - 1 ] := name;
end;

function GetWord(const &where: string; &when: integer): string;
var
  index: integer;
begin
  if IsNameChar(&where[ &when ]) then
  begin
    index := &when;
    while (index <= Length(&where)) and IsNameChar(&where[ index ]) do
      Inc(index);
    GetWord := Copy(&where, &when, index - &when);
  end
  else
    GetWord := '';
end;

function ItIs(const what, &where: string; &when: integer): boolean;
var
  index: integer;
  ans: boolean;
begin
  if &when > 0 then
  begin
    ans := True;
    index := 1;
    while ans and (index <= Length(what)) and (&when + index - 1 <= Length(&where)) do
    begin
      if (&where[ &when + index - 1 ] <> what[ index ]) then
        ans := False;
      Inc(index);
    end;
    if (&when + index - 1 = Length(&where) + 1) then
      ans := false;
    ItIs := ans;
  end
  else
    ItIs := false;
end;

function ItIsWord(const s, code: string; index: integer): boolean;
begin
  ItIsWord := ItIs(s, code, index) and not IsNameChar(code[ index - 1 ]) and not IsNameChar(code[ index + Length(s) ]);
end;

function IsEmpty(const line: string): boolean;
var
  index: integer;
  ans: boolean;
begin
  ans := True;
  index := 1;
  while ans and (index <= Length(line)) do
  begin
    if (line[ index ] <> ' ') then
      ans := False;
    Inc(index);
  end;
  IsEmpty := ans;
end;

procedure SkipBeginEnd(const code: string; var index: integer);
var
  open_blocks: integer;
  finished: boolean;
begin
  open_blocks := 0;
  finished := False;
  (* skip var..const..begin..end parts under functions *)
  while(index <= Length(code)) and ((open_blocks > 0) or not finished) do
  begin
    if ItIsWord('begin', code, index) or ItIsWord('case', code, index) or ItIsWord('repeat', code, index) then
    begin
      Finished := True;
      Inc(open_blocks);
    end
    else if ItIsWord('end', code, index) or ItIsWord('until', code, index) then
      Dec(open_blocks);
    Inc(index);
  end;
end;

procedure SkipUntil(const _what, _where: string; var index: integer);
begin
  while not ItIsWord(_what, _where, index) do
    Inc(index);
end;


var
  basic_file, input_file, output: text;
  code, _string, name, _word: string;
  position, start_index, base_proc_count, index, open_brackets, open_blocks, second_index: integer;
  names, new_names, vars: TNames;
  only_one, in_block, in_cycle, out: boolean;

begin
  (*initialization*)
  SetLength(names, 0);
  SetLength(new_names, 0);
  SetLength(vars, 0);
  (* get basic function and procedure names *)
  Assign(basic_file, 'data.txt');
  Reset(basic_file);
  while not Eof(basic_file) do
  begin
    Readln(basic_file, _string);
    AddName(names, _string);
  end;
  Close(basic_file);
  
  base_proc_count := Length(names);
  
  (* read a code from the input file *)
  Assign(input_file,INPUT_FILE_NAME);
  Reset(input_file);
  code := '     ';
  while not Eof(input_file) do
  begin
    Readln(input_file,_string);
    
    for index := 1 to Length(_string) do
      if IsBigLetter(_string[ index ]) then
        _string[ index ] := Copy('qwertyuiopasdfghjklzxcvbnm', Pos(_string[ index ], 'QWERTYUIOPASDFGHJKLZXCVBNM'), 1)[ 1 ];
    
    index := Length(_string); // delete "strings" in the string
    while (index > 0) do
    begin
      if (_string[ index ] = #39) then
      begin
        start_index := index;
        Dec(index);
        while (_string[ index ] <> #39) do
          Dec(index);
        Delete(
          _string, 
          index, 
          start_index - index + 1
        );
        Dec(index);
      end;
      index -= 1;
    end;
    
    
    position := Pos('///', _string); // delete "///" comments
    if position > 0 then
      _string := Copy(_string, 1, position - 1);
    
    position := Pos('//', _string); // delete "//" comments
    if position > 0 then
      _string := Copy(_string, 1, position - 1);
    
    // delete dooble spaces
    index := Length(_string);
    while (index > 1) do
    begin
      if ItIs('  ', _string, index - 1) then
      begin
        Delete(_string, index, 1);
        Dec(index, 1)
      end
      else
        Dec(index);
    end;
    
    code := code + _string + #13;
  end;
  Close(input_file);
  
  (* delete comments from the code *)
  
  index := Length(code);
  while index > 5 do
  begin
    if (code[ index ] = '}') then // delete "{}" comments
    begin
      start_index := index;
      while (index > 0) and (code[ index ] <> '{') do
        Dec(index);
      Delete(code, index, start_index - index + 1);
      Dec(index);
    end
    else if (code[ index ] = ')') and (index > 1) and (code[ index - 1 ] = '*') then // delete "(**)" comments
    begin
      start_index := index;
      while (index > 1) and not ((code[ index ] = '*') and (code[ index - 1 ] = '(')) do
        Dec(index);
      Delete(code, index - 1, start_index - index + 2);
      Dec(index, 2);
    end
    else if (code[ index ] = ')') then // delete ();
    begin
      start_index := index;
      open_brackets := 1;
      Dec(index);
      while (index > 0) and (open_brackets > 0) do
      begin
        if (code[ index ] = '(') then
          Dec(open_brackets)
        else if (code[ index ] = ')') then
          Inc(open_brackets);
        Dec(index);
      end;
      Delete(code, index + 1, start_index - index);
      Dec(index);
    end
    else
      Dec(index);
  end;
  
  //writeln(code);
  
  index := 1;
  out := false;
  while (index <= Length(code)) and not out do
  begin
    if ItIsWord('procedure', code, index) then
    begin
      (* get already certain procedure names *)
      SkipWord('procedure', index);
      Skip(' ;' + #13, index, code);
      name := GetWord(code, index);
      AddName(names, name);
      SkipWord(name, index);
      Skip(' ;' + #13, index, code);
      
      SkipBeginEnd(code, index);
    end
    else if ItIsWord('function', code, index) then
    begin
      SkipWord('function', index);
      Skip(' ;' + #13, index, code);
      name := GetWord(code, index);
      SkipWord(name, index);
      Skip(' ;:' + #13, index, code);
      name := GetWord(code, index);
      SkipWord(name, index);
      Skip(' ;' + #13, index, code);
      
      SkipBeginEnd(code, index);
    end
    else if ItIsWord('var', code, index) then
    begin
      (* get variable names *)
      in_block := true;
      SkipWord('var', index);
      while in_block do
      begin
        Skip(' ' + #13, index, code);
        while code[ index ] <> ':' do
        begin
          name := GetWord(code, index);
          AddName(vars, name);
          SkipWord(name, index);
          Skip(' ,' + #13, index, code);
        end;
        SkipWord(':', index);
        Skip(' ,' + #13, index, code);
        name := GetWord(code, index);
        SkipWord(name, index);
        Skip(' ,;' + #13, index, code);
        _word := GetWord(code, index);
        if GetIndexIn(Arr('procedure', 'function', 'type', 'begin'),_word)<>-1 then
          in_block := false;
      end;
      Dec(index);
    end
    else if ItIsWord('begin', code, index) then
    begin
      (* finaly make the list of new procedures in the main begin end block *)
      out := true;
      SkipWord('begin', index);
      while (index < length(code)) and (code[ index ] <> '.') and (_word<>'') do
      begin
        Skip(' ;' + #13, index, code);
        if (index = length(code) + 1) then
        else
        begin
          _word := GetWord(code, index);
          SkipWord(_word, index);
          if (_word = 'while') or (_word = 'for') then
          begin
            SkipUntil('do', code, index);
            SkipWord('do', index);
          end
          else if (_word = 'if') then
          begin
            SkipUntil('then', code, index);
            SkipWord('then', index);
          end
          else if (_word = 'begin') or (_word = 'end') or (_word = 'repeat') then
          else if (_word = 'until') then
          begin
            while (code[ index ] <> ';') and not ItIsWord('end', code, index) do
              Inc(index);
            if ItIsWord('end', code, index) then
              SkipWord('end', index);
          end
          else
          if (GetIndexIn(vars, _word) = -1) then
            if (GetIndexIn(names, _word) = -1) and (GetIndexIn(new_names, _word) = -1) and (_word<>'') then
              AddName(new_names, _word)
            else
            else
          begin
            while (code[ index ] <> ';') and not ItIsWord('end', code, index) do
              Inc(index);
            if ItIsWord('end', code, index) then
              SkipWord('end', index);
          end;
          Skip(' ;' + #13, index, code);
        end;
      end;
    end;
    Inc(index);
  end;
  
  Assign(output,OUTPUT_FILE_NAME);
  Rewrite(output);
  for index := 0 to Length(new_names) - 1 do
    writeln(output, new_names[index]);
  if Length(new_names) = 0 then
    writeln(output, 'Undefined procedures has not been found');
  Close(output);
end.