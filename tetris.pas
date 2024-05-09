uses crt, tetris_figures;
{$I-}
const
    {size of playing field} 
    HEIGHT_FIELD = 20;  
    LEN_FIELD = 10;

    {points for lines}
    POINTS: array [1..4] of integer = (100, 300, 700, 1500);

    {colors}
    FIGURE_MENU_COLORS: array of byte = (red, yellow, green, lightBlue, blue, magenta);
    STATISTIC_MENU_COLORS: array of byte = (red, yellow, green, lightBlue, blue, magenta);
    FIELD_BORDER_COLORS: array of byte = (red, yellow, green, lightBlue, blue, magenta);


type
    Figure = record
        x, y, rotation: integer;
        figureType: ^MyFigure;
        blocks: matrix;
    end;

    Cell = record
        fill: boolean;
        x, y: integer;
        color: byte;
    end;

    PlayField = array [0..HEIGHT_FIELD-1, 0..LEN_FIELD-1] of cell;

    {for statistic menu}
    Info = record
        x, y: integer;
        value: longword;
        color: byte;
    end;

    Statistic = record
        lines, score, best, speed, tries, 
        totalScore, totalLines: Info;
    end;

    Menu = record
        x, y, len, height: integer; 
        colors: array of byte;
        title: string;
    end;

    NextFigure = record
        f: Figure;
        x, y: integer;
    end;

    Itemptr = ^Item;
    Item = record
        data: integer;
        next: itemptr;
    end;
    List = record
        first, last: Itemptr;
    end;

const
    {length and height of the cell}
    HEIGHT_CELL = 2; 
    LEN_CELL = 3; 

    {score filename}
    SCORE_FILENAME = 'tetris.stats';

{base}
procedure GetKey(var code: integer);
var
    ch: char;
begin
    ch := ReadKey;
    if ch = #0 then
    begin
        ch := ReadKey;
        code := -ord(ch)
    end
    else
    begin
        code := ord(ch);
    end
end;

procedure PrintHorizontal(x, y, rep: integer; sym: string; 
                            var colors: array of byte);
var
    i, n: integer;
begin
    GotoXY(x, y);
    for i := 0 to rep-1 do
    begin
        n := i mod length(colors);
        TextColor(colors[n]);
        write(sym)
    end;
end;

procedure PrintVertical(x, y, rep: integer; sym: string; 
                            var colors: array of byte);
var
    i, n: integer;
begin
    for i := 0 to rep-1 do
    begin
        GotoXY(x, y + i);
        n := i mod length(colors);
        TextColor(colors[n]);
        write(sym)
    end;
end;

function countDigits(n: longword): integer;
var
    count: integer;
begin
    if n = 0 then
    begin
        countDigits := 1;
        exit
    end;
    count := 0;
    while n > 0 do
    begin
        n := n div 10; 
        count := count + 1;
    end;
    countDigits := count
end;

procedure ListInit(var l: List);
begin
    l.first := nil;
    l.last := nil
end;

function isListEmpty(var l: List): boolean;
begin
    isListEmpty := l.first = nil
end;

procedure ListPushBack(var l: List; n: integer);
begin
    if l.first = nil then
    begin
        new(l.first);
        l.last := l.first
    end
    else
    begin
        new(l.last^.next);
        l.last := l.last^.next
    end;
        l.last^.data := n;
        l.last^.next := nil
end;

procedure ListGet(var l: List; var n: integer);
var
    tmp: itemptr;
begin
    n := l.first^.data;
    tmp := l.first;
    l.first := l.first^.next;
    if l.first = nil then
        l.last := nil;
    dispose(tmp)
end;

function listLength(var l: List): integer;
var
    tmp: itemptr;
    n: integer;
begin
    tmp := l.first;
    n := 0;
    while tmp <> nil do
    begin
        n := n + 1;
        tmp := tmp^.next
    end;
    listLength := n
end;

{field}
procedure PrintFillCell(x, y: integer; color: byte);
var
    i: integer;
begin
    TextColor(color);
    for i := 0 to HEIGHT_CELL-1 do
    begin
        GotoXY(x, y + i);
        write('###')
    end;
end;

procedure PrintEmptyCell(x, y: integer);
var
    i: integer;
begin
    TextColor(White);
    for i := 0 to HEIGHT_CELL-1 do
    begin
        GotoXY(x, y + i);
        write('.  ')
    end;
end;

procedure SetField(var field: PlayField);
var
    i, j, x, y, first_x: integer;
begin
    y := 1;
    first_x := ScreenWidth div 2 - LEN_FIELD * LEN_CELL div 2;
    for i := 0 to HEIGHT_FIELD-1 do
    begin
        x := first_x;
        for j := 0 to LEN_FIELD-1 do
        begin
            field[i][j].x := x;
            field[i][j].y := y;
            field[i][j].fill := false;
            x := x + LEN_CELL;
        end;
        y := y + HEIGHT_CELL;
    end;
end;

procedure PrintField(var field: PlayField);
var
    i, j: integer;
begin
    for i := 0 to HEIGHT_FIELD-1 do
    begin
        for j := 0 to LEN_FIELD-1 do
        begin
            if field[i][j].fill then
                PrintFillCell(field[i][j].x, field[i][j].y,
                              field[i][j].color)
            else
                PrintEmptyCell(field[i][j].x, field[i][j].y)
        end;
    end;
    GotoXY(1, 1)
end;

procedure ClearField(var field: PlayField);
var
    x, y: integer;
begin
    for y := 0 to HEIGHT_FIELD-1 do
        for x := 0 to LEN_FIELD-1 do
            field[y][x].fill := false;
end;

{interface}
procedure PrintMenu(var m: Menu);
var
    coord: integer;
begin
    PrintHorizontal(m.x, m.y, m.len, '=', m.colors);
    PrintHorizontal(m.x, m.y + m.height-1, m.len, '=', m.colors);

    PrintVertical(m.x, m.y+1, m.height-2, '||', m.colors);
    PrintVertical(m.x + m.len-2, m.y+1, m.height-2, '||', m.colors);

    if m.title <> '' then
    begin
        coord := m.x + m.len div 2 - length(m.title) div 2;
        GotoXY(coord, m.y);
        TextColor(white);
        write(m.title)
    end;
end;

procedure PrintFieldBorder(var field: PlayField);
begin
    TextColor(White);

    PrintVertical(field[0][0].x - 2, field[0][0].y, 
        HEIGHT_FIELD * HEIGHT_CELL, '||', FIELD_BORDER_COLORS);

    PrintVertical(field[0][LEN_FIELD-1].x + LEN_CELL, field[0][0].y, 
        HEIGHT_FIELD * HEIGHT_CELL, '||', FIELD_BORDER_COLORS);

    PrintHorizontal(field[0][0].x - 2, field[HEIGHT_FIELD-1][0].y + HEIGHT_CELL,
        LEN_FIELD * LEN_CELL + 4, '=', FIELD_BORDER_COLORS);

    GotoXY(1, 1)
end;

procedure PrintInfo(var inf: Info; filler: char);
var
    len, i: integer;
begin
    GotoXY(inf.x, inf.y);
    TextColor(white);
    len := countDigits(inf.value); 
    for i := 1 to 9 - len do
        write(filler);
    TextColor(inf.color);
    write(inf.value);
end;

procedure SetStatisticMenu(var statisticMenu: Menu);
begin
    statisticMenu.colors := STATISTIC_MENU_COLORS;
    statisticMenu.title := 'STATISTIC';
    statisticMenu.len := 22;
    statisticMenu.height := 12;
    statisticMenu.x := ScreenWidth div 2 + LEN_FIELD * LEN_CELL div 2 + 5;
    statisticMenu.y := 3;
end;

procedure SetStatistic(var stats: Statistic; var statisticMenu: Menu);
var
    x, y: integer;
begin
    x := statisticMenu.x + 10;
    y := statisticMenu.y + 2;

    stats.score.x := x;
    stats.score.y := y;
    stats.score.color := lightBlue;

    stats.best.x := x;
    stats.best.y := y + 1;
    stats.best.color := red;

    stats.lines.x := x;
    stats.lines.y := y + 2;
    stats.lines.color := white;

    stats.speed.x := x;
    stats.speed.y := y + 3;
    stats.speed.color := white;

    stats.totalScore.x := x;
    stats.totalScore.y := y + 6;
    stats.totalScore.color := lightBlue;

    stats.totalLines.x := x;
    stats.totalLines.y := y + 7;
    stats.totalLines.color := white;

    stats.tries.x := x;
    stats.tries.y := y + 8;
    stats.tries.color := white;
end;

procedure SetFigureMenu(var figureMenu: Menu);
begin
    figureMenu.colors := FIGURE_MENU_COLORS;
    figureMenu.title := 'NEXT';
    figureMenu.len := 6 + MATRIX_ORDER * LEN_CELL;
    figureMenu.height := 2 + 4 * HEIGHT_CELL;
    figureMenu.x := ScreenWidth div 2 - LEN_FIELD * LEN_CELL div 2 - 5 - figureMenu.len;
    figureMenu.y := 4;
end;

procedure SetNextFigureCoordinate(var next: NextFigure; var figureMenu: Menu);
begin
    next.x := figureMenu.x + 3;
    next.y := figureMenu.y + 1;
end;

procedure PrintStatisticMenu(var statisticMenu: Menu);
var
    x, y: integer;
begin
    PrintMenu(statisticMenu);
    
    x := statisticMenu.x + 3;
    y := statisticMenu.y + 1;
    TextColor(white);

    GotoXY(x, y);
    write('     Current');
    GotoXY(x, y + 1);
    write('Score:');
    GotoXY(x, y + 2);
    write('Best:');
    GotoXY(x, y + 3);
    write('Lines:');
    GotoXY(x, y + 4);
    write('Speed:');

    GotoXY(x, y + 6);
    write('     Total');
    GotoXY(x, y + 7);
    write('Score:');

    GotoXY(x, y + 8);
    write('Lines:');
    GotoXY(x, y + 9);
    write('Tries:');
end;

procedure PrintInterface(var stats: Statistic; var next: NextFigure);
var
    figureMenu, statisticMenu: Menu;
begin
    SetStatisticMenu(statisticMenu);
    SetFigureMenu(figureMenu);

    SetStatistic(stats, statisticMenu);
    SetNextFigureCoordinate(next, figureMenu);

    PrintStatisticMenu(statisticMenu);
    PrintMenu(figureMenu);
end;

{statistic}
procedure InitStatistic(var stats: Statistic);
begin
    stats.tries.value := stats.tries.value + 1;
    stats.best.color := red;
    stats.lines.value := 0;
    stats.score.value := 0;
    stats.speed.value := 16;
end;

procedure PrintStatistic(var stats: Statistic);
begin
    PrintInfo(stats.score, '0');
    PrintInfo(stats.best, '0');
    PrintInfo(stats.lines, ' ');
    PrintInfo(stats.speed, ' ');
    PrintInfo(stats.totalScore, '0');
    PrintInfo(stats.totalLines, ' ');
    PrintInfo(stats.tries, ' ');
    GotoXY(1, 1)
end;

procedure UpdateStatistic(var stats: Statistic; lines: integer);
var
    newSpeed: integer;
begin
    stats.lines.value := stats.lines.value + lines;
    stats.score.value := stats.score.value + POINTS[lines];

    stats.totalScore.value := stats.totalScore.value + POINTS[lines];
    stats.totalLines.value := stats.totalLines.value + lines;

    newSpeed := round(16 - (stats.score.value div 1500) * 0.61);
    if newSpeed > 0 then
        stats.speed.value := newSpeed
    else
        stats.speed.value := 0;

    if stats.score.value > stats.best.value then
    begin
        stats.best.value := stats.score.value;
        stats.best.color := green;
    end;
    PrintStatistic(stats);
end;

procedure ReadStatisticFile(var stats: Statistic);
var
    scoreFile: file of longword;
begin
    assign(scoreFile, SCORE_FILENAME);
    reset(scoreFile);
    if IOResult = 0 then
    begin
        read(scoreFile, stats.best.value);
        read(scoreFile, stats.totalScore.value);
        read(scoreFile, stats.totalLines.value);
        read(scoreFile, stats.tries.value);
        close(scoreFile)
    end
end;

procedure WriteStatisticFile(var stats: Statistic);
var
    scoreFile: file of longword;
begin
    assign(scoreFile, SCORE_FILENAME);
    rewrite(scoreFile);
    if IOResult = 0 then
    begin
        write(scoreFile, stats.best.value);
        write(scoreFile, stats.totalScore.value);
        write(scoreFile, stats.totalLines.value);
        write(scoreFile, stats.tries.value);
        close(scoreFile)
    end;
end;

{game logic}
{figure}

{seek first non-zero element in matrix save its x, y coordinate}
{if matrix is zero x = y = -1}
procedure SeekFirstElement(var m: Matrix; var x, y: integer);
var
    i, j: integer;
begin
    x := -1;
    y := -1;
    for i := 0 to MATRIX_ORDER-1 do begin
        for j := 0 to MATRIX_ORDER-1 do begin
            if m[i][j] <> 0 then
            begin
                y := i;
                x := j;
                exit;
            end;
		end;
	end;
end;

procedure InitFigure(var f: Figure);
var
    rand, x, y: integer;
begin
    rand := random(length(FIGURES));
    f.figureType := FIGURES[rand]; 
    f.rotation := 0;
    f.blocks := f.figureType^.rotations[0];
    SeekFirstElement(f.blocks, x, y);
    f.y := 0 - y;
    f.x := LEN_FIELD div 2 - MATRIX_ORDER div 2;
end;

procedure PrintNextFigure(var next: NextFigure);
var
    i, j, x, y: integer;
begin
    x := next.x;
    y := next.y;

    for i := 0 to MATRIX_ORDER-1 do
    begin
        for j := 0 to MATRIX_ORDER-1 do
        begin
            if next.f.blocks[i][j] <> 0 then
                PrintFillCell(x, y, next.f.figureType^.color)
            else
                PrintEmptyCell(x, y);
            x := x + LEN_CELL;
        end;
        x := next.x;
        y := y + HEIGHT_CELL;
    end;
    GotoXY(1, 1)
end;

function isFigureOutOfBounds(var f: figure; var field: PlayField): boolean;
var
    x, y: integer;
begin
    for y := 0 to MATRIX_ORDER-1 do
        for x := 0 to MATRIX_ORDER-1 do
            if (f.blocks[y][x] <> 0) and (
				(f.x + x < 0) or 
				(f.x + x > LEN_FIELD-1) or 
				(f.y + y < 0) or
				(f.y + y > HEIGHT_FIELD-1) or
				(field[f.y+y][f.x+x].fill) ) then
            begin
                isFigureOutOfBounds := true;
                exit;
            end;
    isFigureOutOfBounds := false;
end;

procedure HideFigure(var f: figure; var field: PlayField);
var
    x, y: integer;
begin
    for y := 0 to MATRIX_ORDER-1 do
        for x := 0 to MATRIX_ORDER-1 do
            if f.blocks[y][x] <> 0 then
            begin
                PrintEmptyCell(field[y+f.y][x+f.x].x, 
                              field[y+f.y][x+f.x].y)
            end;
    GotoXY(1, 1)
end;

procedure PrintFigure(var f: figure; var field: PlayField);
var
    x, y: integer;
begin
    for y := 0 to MATRIX_ORDER-1 do
        for x := 0 to MATRIX_ORDER-1 do
            if f.blocks[y][x] <> 0 then
            begin
                PrintFillCell(field[y+f.y][x+f.x].x, 
                              field[y+f.y][x+f.x].y,
                              f.figureType^.color)
            end;
    GotoXY(1, 1)
end;

procedure RotateFigure(var f: figure; var field: PlayField);
var
    tmp: figure;
    nextRotation: integer;
begin
    tmp := f;
    nextRotation := (tmp.rotation + 1) mod length(tmp.figureType^.rotations);
    tmp.rotation := nextRotation;
    tmp.blocks := tmp.figureType^.rotations[nextRotation];
    if not isFigureOutOfBounds(tmp, field) then
    begin
        HideFigure(f, field);
        f := tmp;
        PrintFigure(f, field);
    end
end;

procedure MoveFigure(var f: figure; x, y: integer; var field: PlayField);
var
    tmp: figure;
begin
    tmp := f;
    tmp.x := tmp.x + x; 
    tmp.y := tmp.y + y;
    if not isFigureOutOfBounds(tmp, field) then
    begin
        HideFigure(f, field);
        f := tmp;
        PrintFigure(f, field);
    end
end;

function hasCollision(var f: figure; var field: PlayField): boolean;
var
    x, y: integer;
begin
    for y := 0 to MATRIX_ORDER-1 do
        for x := 0 to MATRIX_ORDER-1 do
            if (f.blocks[y][x] <> 0) and (
               (f.y + y = HEIGHT_FIELD-1) or
               (field[f.y + y + 1][f.x + x].fill) ) then
            begin
                hasCollision := true;
                exit
            end;
    hasCollision := false
end;

procedure LockFigure(var f: figure; var field: PlayField);
var
    x, y: integer;
begin
    for y := 0 to MATRIX_ORDER-1 do
        for x := 0 to MATRIX_ORDER-1 do
            if f.blocks[y][x] <> 0 then
            begin
                field[y+f.y][x+f.x].fill := true;
                field[y+f.y][x+f.x].color := f.figureType^.color;
            end
end;

function isRowFull(y: integer; var field: PlayField): boolean;
var
    rowFull: boolean;
    x: integer;
begin
    x := 0;
    rowFull := true;
    while (x <= LEN_FIELD-1) and rowFull do
    begin
        rowFull := field[y][x].fill;
        x := x + 1
    end;
    isRowFull := rowFull;
end;

procedure GetFullRows(var rows: List; var field: PlayField);
var
    y: integer;
begin
    for y := 0 to HEIGHT_FIELD-1 do
        if isRowFull(y, field) then
            ListPushBack(rows, y)
end;

procedure WipeRows(var rows: List; var field: PlayField);
var
    x: integer;
    tmp: itemptr;
begin
    for x := 0 to LEN_FIELD-1 do
    begin
        tmp := rows.first;
        while tmp <> nil do
        begin
            field[tmp^.data][x].fill := false;
            PrintEmptyCell(field[tmp^.data][x].x, 
                           field[tmp^.data][x].y);
            tmp := tmp^.next;
        end;
        GotoXY(1, 1);
        Delay(20)
    end
end;

procedure OmitBlocks(var rows: List; var field: PlayField);
var
    x, y: integer;
begin
    while not isListEmpty(rows) do
    begin
        ListGet(rows, y);
        while y >= 0 do
        begin
            for x := 0 to LEN_FIELD-1 do
                if field[y][x].fill then
                begin
                    field[y][x].fill := false;
                    field[y + 1][x].fill := true;
                    field[y + 1][x].color := field[y][x].color
                end;
            y := y - 1;
        end;
    end
end;

procedure ClearLines(var stats: Statistic; var field: PlayField);
var
    rows: List;
begin
    ListInit(rows);
    GetFullRows(rows, field);
    if not isListEmpty(rows) then
    begin
        UpdateStatistic(stats, listLength(rows));
        WipeRows(rows, field);
        OmitBlocks(rows, field);
        PrintField(field);
    end
end;

function isPlayerLose(var f: figure; var field: PlayField): boolean;
var
    x, y: integer;
begin
    for y := 0 to MATRIX_ORDER-1 do
        for x := 0 to MATRIX_ORDER-1 do
            if (f.blocks[y][x] <> 0) and 
            field[f.y+y][f.x+x].fill then
            begin
                isPlayerLose := true;
                exit
            end;
    isPlayerLose := false
end;

procedure GameOverAnimation(var field: PlayField);
var
    x, y: integer;
    randomFigure: ^MyFigure;
begin
    for y := HEIGHT_FIELD-1 downto 0 do
        for x := 0 to LEN_FIELD-1 do
            if not field[y][x].fill then
            begin
                randomFigure := FIGURES[random(length(FIGURES))];
                PrintFillCell(field[y][x].x, field[y][x].y,
                             randomFigure^.color);
                GotoXY(1, 1);
                Delay(10);
            end
end;

procedure RestartAnimation(var field: PlayField);
var
    x, y: integer;
begin
    for x := 0 to LEN_FIELD-1 do
    begin
        for y := 0 to HEIGHT_FIELD-1 do
            PrintEmptyCell(field[y][x].x, field[y][x].y);
        GotoXY(1, 1);
        Delay(100)
    end;
end;

procedure GameOver(var field: PlayField);
begin
    GameOverAnimation(field);
    RestartAnimation(field);
    ClearField(field);
    while KeyPressed do ReadKey;
end;

procedure FinishGame(var stats: Statistic);
begin
    WriteStatisticFile(stats);
    Clrscr;
    write(#27'[0m'); {reset}
	halt;
end;

procedure HandleUserInput(var field: PlayField; var f: Figure; var stats: Statistic); 
var
	counter, code: integer;
begin
	for counter := 0 to 30 do
	begin
		if KeyPressed then
		begin
			GetKey(code);
			case code of
				-72, 119: RotateFigure(f, field);      	{ up }  
				-75, 97: MoveFigure(f, -1, 0, field);  	{ left }
				-77, 100: MoveFigure(f, 1, 0, field);  	{ right }
				-80, 115: MoveFigure(f, 0, 1, field);  	{ down }
				27: FinishGame(stats); 					{ esc }
			end;
		end;
		delay(stats.speed.value);
	end;
end;

procedure Play(var field: PlayField; var stats: Statistic; var next: NextFigure);
var
    f: Figure;
begin
    InitFigure(f);
    InitFigure(next.f);
    InitStatistic(stats);

    PrintFigure(f, field);
    PrintNextFigure(next);
    PrintStatistic(stats);

    while true do
    begin
		HandleUserInput(field, f, stats);

        if not hasCollision(f, field) then
		begin
            MoveFigure(f, 0, 1, field);
			continue;
		end;

		LockFigure(f, field);
		f := next.f;
		InitFigure(next.f);
		PrintNextFigure(next);
		ClearLines(stats, field);
		if isPlayerLose(f, field) then
		begin
			GameOver(field);
			exit
		end;
		PrintFigure(f, field);

    end;
end;

var 
    field: PlayField; 
    stats: Statistic;
    next: NextFigure;
begin

    if (screenWidth < 81) or 
       (screenHeight < HEIGHT_CELL * HEIGHT_FIELD + 1) then
    begin
        writeln('Please increase the window size' +
            ' or reduce HEIGHT_FIELD/LENGTH_FIELD in tetris.pas');
        halt(1);
    end;
    clrscr;
    randomize;

    ReadStatisticFile(stats);
    SetField(field);

    PrintInterface(stats, next);
    PrintField(field);
    PrintFieldBorder(field);

	while true do
		Play(field, stats, next);
end.
