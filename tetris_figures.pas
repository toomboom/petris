unit tetris_figures;

interface
uses crt;
const MATRIX_ORDER = 4;
type
    Matrix = array [0..MATRIX_ORDER-1, 0..MATRIX_ORDER-1] of byte;

    MyFigure = record
        color: byte; rotations: array of matrix;
    end;

var FIGURES: array of ^MyFigure;

implementation
var
    jFigure: MyFigure = (
        color: yellow;
        rotations: (
           ((0,0,0,0),          
            (0,1,1,1),
            (0,0,0,1),
            (0,0,0,0)),

           ((0,0,1,1), 
            (0,0,1,0),
            (0,0,1,0),
            (0,0,0,0)),
            
           ((0,1,0,0),
            (0,1,1,1),
            (0,0,0,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,0,1,0),
            (0,1,1,0),
            (0,0,0,0))
        );
    );

    iFigure: MyFigure = (
        color: lightCyan;
        rotations: (
           ((0,0,0,0),
            (1,1,1,1),
            (0,0,0,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,0,1,0),
            (0,0,1,0),
            (0,0,1,0))
        );
    );

    oFigure: MyFigure = (
        color: red;
        rotations: (
           ((0,0,0,0),
            (0,1,1,0),
            (0,1,1,0),
            (0,0,0,0))
        );
    );

    lFigure: MyFigure = (
        color: lightBlue;
        rotations: (
           ((0,0,0,0),
            (0,1,1,1),
            (0,1,0,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,0,1,0),
            (0,0,1,1),
            (0,0,0,0)),

           ((0,0,0,1),
            (0,1,1,1),
            (0,0,0,0),
            (0,0,0,0)),

           ((0,1,1,0),
            (0,0,1,0),
            (0,0,1,0),
            (0,0,0,0))
        );
    );

    zFigure: MyFigure = (
        color: lightRed;
        rotations: ( 
           ((0,0,0,0),
            (0,1,1,0),
            (0,0,1,1),
            (0,0,0,0)),

           ((0,0,0,1),
            (0,0,1,1),
            (0,0,1,0),
            (0,0,0,0))
        );
    );

    tFigure: MyFigure = (
        color: lightMagenta;
        rotations: (
           ((0,0,0,0),
            (0,1,1,1),
            (0,0,1,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,0,1,1),
            (0,0,1,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,1,1,1),
            (0,0,0,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,1,1,0),
            (0,0,1,0),
            (0,0,0,0))
        );
    );

    sFigure: MyFigure = ( 
        color: lightGreen;
        rotations: (
           ((0,0,0,0),
            (0,0,1,1),
            (0,1,1,0),
            (0,0,0,0)),

           ((0,0,1,0),
            (0,0,1,1),
            (0,0,0,1),
            (0,0,0,0))
        );
    );

    {array of pointers on figures. You can create and add your own figure}
    playFigures: array of ^MyFigure = 
		(@jFigure, @iFigure, @oFigure, @lFigure, @zFigure, @tFigure, @sFigure);

begin
    FIGURES := playFigures;
end.
