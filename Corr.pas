// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2017, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit Corr;

interface

uses SysUtils, Math, MatrixConst, Matrix, BaseMathPersistence, Types;

// standard simple linear correlation method:
type
  TCorrelation = class(TObject)
  protected
    function InternalCorrelate(w1, w2 : IMatrix) : double;
  public
    function Correlate(x, y : IMatrix) : double; // correlation coefficient between t, r (must have the same length)
    function Covariance(x, y : IMatrix; Unbiased : boolean = True) : IMatrix; overload; // covariance matrix
    function Covariance(A : IMatrix; Unbiased : boolean = True) : IMatrix; overload;   // covariance matrix of matrix A
  end;

// see: https://en.wikipedia.org/wiki/Dynamic_time_warping
// based on Timothy Felty's matlab script (google timothy felty dynamic time warping)
// -> enhanced with maximum search window
// -> enhanced with different distance methods
// Added the recursive fast dtw method based on 
//    FastDTW: Toward Accurate Dynamic Time Warping in Linear Time and Space 
type
  TDynamicTimeWarpDistMethod = (dtwSquared, dtwAbsolute, dtwSymKullbackLeibler);
  TDynamicTimeWarp = class(TCorrelation)
  private
    type
      TCoordRec = record
        i, j : integer;
      end;
      TDistRec = record
        next : TCoordRec;
        curr : TCoordRec;
        dist : double;
      end;
  private
    fd : IMatrix;
    fAccDist : IMatrix;
    fW1, fW2 : IMatrix;  
    fNumW : integer;
    fMaxSearchWin : integer;
    fMethod : TDynamicTimeWarpDistMethod;

    fX : TDoubleDynArray;
    fY : TDoubleDynArray;
    fWindow : Array of TCoordRec; // pairs of x and y indices. Used in dtw and fastdtw
    fDistIdx : Array of TDistRec;
    fPath : Array of TCoordRec;    // i, j that build up the path
    fNumPath : Integer;

    fMaxPathLen : integer;
    fMaxWinLen : integer;
    
    // fastdtw implementation based on the python package on: https://pypi.python.org/pypi/fastdtw
    // and: Stan Salvador, and Philip Chan. �FastDTW: Toward accurate dynamic time warping in linear time and space.�  Intelligent Data Analysis 11.5 (2007): 561-580.
    procedure ReduceByHalf(const X : TDoubleDynArray; inLen, inOffset : integer; out newLen, newOffset : Integer);
    function ExpandWindow(inXLen, inYLen : integer; radius : integer) : Integer;
    
    procedure InternalFastDTW(inXOffset, inXLen, inYOffset, inYLen : integer; radius : integer; var dist : double);
    function InternalDTW(inXOffset, inXLen, inYOffset, inYLen : integer; window : integer) : double;
    procedure DictNewCoords(var i, j, MaxDictIdx: integer); inline;
    function DictValue(i, j, MaxDictIdx: integer): double; inline;
  public
    property W1 : IMatrix read fW1;  // stores the last result (warped vector)
    property W2 : IMatrix read fW2;
  
    property MaxPathLen : integer read fMaxPathLen;
    property MaxWinLen : integer read fMaxWinLen;
  
    function DTW(t, r : IMatrix; var dist : double; MaxSearchWin : integer = 0) : IMatrix; 
    function DTWCorr(t, r : IMatrix; MaxSearchWin : integer = 0) : double;  // calculate the correlation coefficient between both warped vectors

    function FastDTW(x, y : IMatrix; var dist : double; Radius : integer = 1)  : IMatrix; // applies fastdtw
    function FastDTWCorr(t, r : IMatrix; Radius : integer = 1) : double;  // calculate the correlation coefficient between both warped vectors
    
    constructor Create(DistMethod : TDynamicTimeWarpDistMethod = dtwSquared); // -> 0 = infinity
  end;

implementation

uses OptimizedFuncs;

// ###########################################
// #### Correlation (base implementation)
// ###########################################

// note: afterwards w1 and w2 are mean normalized and w2 width and height is changed!
function TCorrelation.Correlate(x, y: IMatrix): double;
var w1, w2 : IMatrix;
begin
     w1 := x;
     if x.Height <> 1 then
        w1 := x.Reshape(x.Width*x.Height, 1);
     w2 := y;
     if y.Height <> 1 then
        w2 := y.Reshape(y.Width*y.Height, 1);

     assert(w1.Width = w2.Width, 'Dimension error');
     
     Result := InternalCorrelate(w1, w2);
end;

function TCorrelation.Covariance(x, y: IMatrix; Unbiased : boolean = True): IMatrix;
var xc, tmp : IMatrix;
begin
     if x.Width*x.Height <> y.Width*y.Height then
        raise Exception.Create('Error length of x and y must be the same');

     xc := TDoubleMatrix.Create(2, x.Width*x.Height);

     // build matrix with 2 columns
     if x.Width = 1 
     then
         tmp := x
     else
         tmp := x.Reshape(1, x.Width*x.Height, True);
     xc.SetColumn(0, tmp);

     if y.Width = 1 
     then
         tmp := y
     else
         tmp := y.Reshape(1, x.Width*x.Height, True);
     xc.SetColumn(1, tmp);
     
     Result := Covariance(xc, Unbiased);
end;

// each row is an observation, each column a variable
function TCorrelation.Covariance(A: IMatrix; Unbiased: boolean): IMatrix;
var aMean : IMatrix;
    ac : IMatrix;
    tmp : IMatrix;
    m : Integer;
begin
     aMean := A.Mean(False);

     ac := TDoubleMatrix.Create(A.Width, A.Height);
     for m := 0 to A.Height - 1 do
     begin
          ac.SetSubMatrix(0, m, ac.Width, 1);
          ac.SetRow(0, A, m);
          ac.SubInPlace(aMean);
     end;
     ac.UseFullMatrix;

     m := ac.Height; 
     tmp := ac.Transpose;
     ac := tmp.Mult(ac);
    
     if Unbiased then
        dec(m);

     if m > 0 then
        ac.ScaleInPlace(1/m);

     Result := ac;
end;

function TCorrelation.InternalCorrelate(w1, w2: IMatrix): double;
var meanVar1 : Array[0..1] of double;
    meanVar2 : Array[0..1] of double;
begin
     // note the routine avoids memory allocations thus it runs on the raw optimized functions:
     
     // calc: 1/(n-1)/(var_w1*var_w2) sum_i=0_n (w1_i - mean_w1)*(w2_i - mean_w2)
     MatrixMeanVar( @meanVar1[0], 2*sizeof(double), w1.StartElement, w1.LineWidth, w1.Width, 1, True, True);
     MatrixMeanVar( @meanVar2[0], 2*sizeof(double), w2.StartElement, w2.LineWidth, w2.Width, 1, True, True);

     w1.AddInPlace( -meanVar1[0] );     
     w2.AddInPlace( -meanVar2[0] );

     // dot product:
     MatrixMult( @Result, sizeof(double), w1.StartElement, w2.StartElement, w1.Width, w1.Height, w2.Height, w2.Width, w1.LineWidth, sizeof(double) );
     Result := Result/sqrt(meanVar1[1]*meanVar2[1])/(w1.Width - 1);
end;

// ###########################################
// #### Dynamic time warping
// ###########################################

{ TDynamicTimeWarp }

constructor TDynamicTimeWarp.Create(DistMethod : TDynamicTimeWarpDistMethod = dtwSquared); 
begin
     fMethod := DistMethod;

     inherited Create;
end;

// ###########################################
// #### Base DTW algorithm
// ###########################################

function TDynamicTimeWarp.DTW(t, r: IMatrix; var dist: double; MaxSearchWin : integer = 0): IMatrix;
var n, m : integer;
    counter: Integer;
begin
     fMaxSearchWin := MaxSearchWin;
     
     // ###########################################
     // #### Prepare memory
     if not Assigned(fd) or (fd.Width <> t.Width) or (fd.Height <> r.Width) then
     begin
          fd := TDoubleMatrix.Create( t.Width, r.Width );
          fAccDist := TDoubleMatrix.Create(t.Width, r.Width);
          SetLength(fWindow, 2*max(r.Width, t.Width));
          fW1 := TDoubleMatrix.Create(Length(fWindow), 1);
          fW2 := TDoubleMatrix.Create(Length(fWindow), 1);
     end;
     fNumW := 0;

     // ###########################################
     // #### prepare distance matrix
     fd.SetValue(MaxDouble);
     for m := 0 to fd.Height - 1 do
     begin
          for n := 0 to fd.Width - 1 do
          begin
               if (fMaxSearchWin <= 0) or ( abs(n - m) <= fMaxSearchWin) then
               begin
                    case fMethod of
                      dtwSquared: fd[n, m] := sqr( t.Vec[n] - r.Vec[m] );
                      dtwAbsolute: fd[n, m] := abs( t.Vec[n] - r.Vec[m] );
                      dtwSymKullbackLeibler: fd[n, m] := (t.Vec[n] - r.Vec[m])*(ln(t.Vec[n]) - ln(r.Vec[m]));
                    end;
               end;
          end;
     end;
     
     fAccDist.SetValue(0);
     fAccDist[0, 0] := fd[0, 0];

     for n := 1 to fd.Width - 1 do
         fAccDist[n, 0] := fd[n, 0] + fAccDist[n - 1, 0];
     for m := 1 to fd.Height - 1 do
         fAccDist[0, m] := fd[0, m] + fAccDist[0, m - 1];
     for n := 1 to fd.Height - 1 do
         for m := 1 to fd.Width - 1 do
             fAccDist[m, n] := fD[m, n] + min( fAccDist[ m, n - 1 ], min( fAccDist[m - 1, n - 1], fAccDist[ m - 1, n] ));
     
     dist := fAccDist[fd.Width - 1, fd.Height - 1];

     fNumW := 0;
     m := t.Width - 1;
     n := r.Width - 1;
     fWindow[fNumW].i := m;
     fWindow[fNumW].j := n;
     inc(fNumW);
     
     while (n + m) > 1 do
     begin
          if n - 1 <= 0 
          then
              dec(m)
          else if m - 1 <= 0 
          then
              dec(n)
          else
          begin
               if fAccDist[m - 1, n - 1] < Min(fAccDist[m, n - 1], fAccDist[m - 1, n]) then
               begin
                    dec(n);
                    dec(m);
               end
               else if fAccDist[m, n - 1] < fAccDist[m - 1, n] 
               then
                   dec(n)
               else
                   dec(m);
          end;

          fWindow[fNumW].i := m;
          fWindow[fNumW].j := n;

          inc(fNumW);
     end;

     // ###########################################
     // #### Build final warped vector
     fw1.SetSubMatrix(0, 0, fNumW, 1);
     fw2.SetSubMatrix(0, 0, fNumW, 1);
     Result := fW1;
     for counter := 0 to fNumW - 1 do
     begin
          fw1.Vec[counter] := r.Vec[ fWindow[fNumW - 1 - counter].j ];
          fw2.Vec[counter] := t.Vec[ fWindow[fNumW - 1 - counter].i ]; 
     end;
end;

function TDynamicTimeWarp.DTWCorr(t, r: IMatrix; MaxSearchWin : integer = 0): double;
var dist : double;
begin
     // ###########################################
     // #### Create time warping vectors -> stored in fw1, fw2
     DTW(t, r, dist, MaxSearchWin);
     
     // ###########################################
     // #### Calculate correlation
     Result := InternalCorrelate(fw1, fw2);
end;

// ###########################################
// #### Fast DTW
// ###########################################

function TDynamicTimeWarp.FastDTW(x, y: IMatrix; var dist: double; Radius : integer = 1): IMatrix;
var counter: Integer;
begin
     dist := 0;

     radius := Max(1, radius);

     // ###########################################
     // #### Preparation
     fMaxPathLen := 0;
     fMaxWinLen := 0;
     
     if Length(fX) < 2*x.Width then
        SetLength(fX, 2*x.Width);
     Move(x.StartElement^, fx[0], sizeof(double)*x.Width);
     if Length(fY) < 2*y.Width then
        SetLength(fy, 2*y.Width);
     Move(y.StartElement^, fy[0], sizeof(double)*y.Width);

     // prepare memory
     if Length(fWindow) < Max(x.Width, y.Width)*2 then
     begin
          SetLength(fWindow, (radius*4 + 4)*Max(x.Width, y.Width));
          SetLength(fPath, 3*Max(x.Width, y.Width));
          SetLength(fDistIdx, Length(fWindow));
     end;
     
     // ###########################################
     // #### Find optimal path
     fNumPath := 0;
     InternalFastDTW(0, x.Width, 0, y.Width, Max(1, Radius), dist);


     // ###########################################
     // #### Build result
     if not Assigned(fW1) then
     begin
          fW1 := TDoubleMatrix.Create(fNumPath, 1);
          fW2 := TDoubleMatrix.Create(fNumPath, 1);
     end;
     fW1.UseFullMatrix;
     fW2.UseFullMatrix;

     if fW1.Width < fNumPath then
     begin
          fW1.SetWidthHeight(fNumPath, 1);
          fW2.SetWidthHeight(fNumPath, 1);
     end;
     
     fW1.SetSubMatrix(0, 0, fNumPath, 1);
     fW2.SetSubMatrix(0, 0, fNumPath, 1);
     
     for counter := 0 to fNumPath - 1 do
     begin
          fW1.Vec[counter] := fX[fPath[counter].i];
          fW2.Vec[counter] := fY[fPath[counter].j];
     end;

     Result := FW1;
end;

function TDynamicTimeWarp.FastDTWCorr(t, r: IMatrix; Radius : integer = 1): double;
var dist : double;
begin
     // ###########################################
     // #### Create time warping vectors -> stored in fw1, fw2
     FastDTW(t, r, dist, radius);

     // ###########################################
     // #### Calculate correlation
     Result := InternalCorrelate(fw1, fw2);
end;

// ###########################################
// #### path functions
// ###########################################

function TDynamicTimeWarp.DictValue(i, j : integer; MaxDictIdx : integer) : double; 
var cnt : integer;
begin
     Result := MaxDouble;

     for cnt := MaxDictIDx - 1 downto 0 do
     begin
          if (i = fDistIdx[cnt].curr.i) and (j = fDistIdx[cnt].curr.j) then
          begin
               Result := fDistIdx[cnt].dist;
               break;
          end;
     end;
end;

procedure TDynamicTimeWarp.DictNewCoords(var i, j : integer; var MaxDictIdx : integer); 
begin
     dec(MaxDictIdx);
     while (MaxDictIdx >= 0) and ((fDistIdx[MaxDictIdx].curr.i <> i) or (fDistIdx[maxDictIdx].curr.j <> j)) do
           dec(MaxDictIdx);

     if MaxDictIdx >= 0 then
     begin
          i := fDistIdx[MaxDictIdx].next.i;
          j := fDistIdx[MaxDictIdx].next.j;
     end;
end;

// ###########################################
// #### private fast dtw functions
// ###########################################

function TDynamicTimeWarp.InternalDTW(inXOffset, inXLen, inYOffset, inYLen : integer; window : integer) : double;
var i, j : Integer;
    cnt : integer;
    dt : double;
    dIdx : integer;
    dist0, dist1, dist2 : double;
    tmp : TCoordRec;
begin
     // perform a full inXLen*inYLen coordinate space
     if window = 0 then
     begin
          if Length(fWindow) < inXLen*inYLen then
             SetLength(fWindow, inXLen*inYLen);
          
          for i := 1 to inXLen do
          begin
               for j := 1 to inYLen do
               begin
                    fWindow[window].i := i;
                    fWindow[window].j := j;
                    inc(window);
               end;
          end;
     end;

     fMaxWinLen := Max(fMaxWinLen, window);

     if Length( fDistIdx ) < (inXLen*inYLen) then
        SetLength( fDistIdx, inXLen*inYLen );

     // ###########################################
     // #### Prepare a path list through the given coordinate list
     // first we take a forward step through a given set of coordinates
     // and then search back for the shortest path
     fDistIdx[0].dist := 0;
     fDistIdx[0].next.i  := 0;
     fDistIdx[0].next.j := 0;
     fDistIdx[0].curr.i := 0;
     fDistIdx[0].curr.j := 0;
     
     dIdx := 1;
     
     for cnt := 0 to window - 1 do
     begin
          i := fWindow[cnt].i;
          j := fWindow[cnt].j;

          case fMethod of
            dtwSquared: dt := sqr( fX[inXOffset + i - 1] - fY[inYOffset + j - 1]);
            dtwAbsolute: dt := abs( fX[inXOffset + i - 1] - fY[inYOffset + j - 1] );
            dtwSymKullbackLeibler: dt := fX[inXOffset + i - 1] - fY[inYOffset + j - 1]*(ln(fX[inXOffset + i - 1]) - ln(fY[inYOffset + j - 1]));
          else
              dt := abs( fX[inXOffset + i - 1] - fY[inYOffset + j - 1] );;
          end;

          dist0 := DictValue(i - 1, j, dIdx);
          dist1 := DictValue(i, j - 1, dIdx);
          dist2 := DictValue(i - 1, j - 1, dIdx);

          if (dist0 = cMaxDouble) and (dist1 = cMaxDouble) and (dist2 = cMaxDouble) then
             continue;
          
          fDistIdx[dIdx].curr.i := i;
          fDistIdx[dIdx].curr.j := j;
          
          // according to the distance measure store the path coordinates for the next step
          if dist2 <= Min(dist1, dist0) then
          begin
               fDistIdx[dIdx].dist := dist2 + dt;
               fDistIdx[dIdx].next.i := i - 1;
               fDistIdx[dIdx].next.j := j - 1;
          end 
          else if dist0 < Min(dist1, dist2) then
          begin
               fDistIdx[dIdx].dist := dist0 + dt;
               fDistIdx[dIdx].next.i := i - 1;
               fDistIdx[dIdx].next.j := j;
          end
          else 
          begin
               fDistIdx[dIdx].dist := dist1 + dt;
               fDistIdx[dIdx].next.i := i;
               fDistIdx[dIdx].next.j := j - 1;
          end;
          inc(dIdx);
     end;
      
     // ###########################################
     // #### Build path (backwards)
     Result := fDistIdx[dIdx - 1].dist;
     i := inXLen;  
     j := inYLen;
     fNumPath := 0;
     while ( (i > 0) and (j > 0) ) and (dIdx >= 0) do
     begin
          fPath[fNumPath].i := i - 1;
          fPath[fNumPath].j := j - 1;
          inc(fNumPath);
          
          DictNewCoords(i, j, dIdx);
     end;

     // reverse path
     i := 0;
     j := fNumPath - 1;
     while i < j do
     begin
          tmp := fPath[i];
          fPath[i] := fPath[j];
          fPath[j] := tmp; 

          inc(i);
          dec(j);
     end;

     fMaxPathLen := Max(fMaxPathLen, fNumPath);
end;

procedure TDynamicTimeWarp.InternalFastDTW(inXOffset, inXLen, inYOffset, inYLen : integer; radius : integer; var dist : double);
var minTimeSize : Integer;
    newXOffset, newXLen : integer;
    newYOffset, newYLen : Integer;
    windowCnt : integer;
begin
     minTimeSize := radius + 2;

     // check for break condition
     if (inXLen < minTimeSize) or (inYLen < minTimeSize) then
     begin
          dist := InternalDTW(inXOffset, inXLen, inYOffset, inYLen, 0);
          exit;
     end;

     // reduce by half recursively
     ReduceByHalf(fX, inXLen, inXOffset, newXLen, newXOffset);
     ReduceByHalf(fY, inYLen, inYOffset, newYLen, newYOffset);
     InternalFastDTW(newXOffset, newXLen, newYOffset, newYLen, radius, dist);

     // rebuild 
     windowCnt := ExpandWindow(inXLen, inYLen, radius);
     dist := InternalDTW(inXOffset, inXLen, inYOffset, inYLen, windowCnt);
end;

procedure TDynamicTimeWarp.ReduceByHalf(const X : TDoubleDynArray; inLen, inOffset : integer; out newLen, newOffset : Integer);
var counter: Integer;
    idx : Integer;
begin
     newOffset := inOffset + inLen;
     newLen := inLen div 2;
     idx := inOffset;
     for counter := newOffset to newOffset + newLen - 1 do
     begin
          X[counter] := 0.5*(x[idx] + X[idx + 1]);
          inc(idx, 2);
     end;
end;

function TDynamicTimeWarp.ExpandWindow(inXLen, inYLen, radius: integer): Integer;
var cnt : integer;
    baseI, baseJ : integer;
    minJ, maxJ : integer;
    pathCnt : integer;
    prevRadiusPathIdx : integer;
    nextRadiusPathIdx : integer;
    i, j : integer;
    base : integer;
begin
     Result := 0;
     
     prevRadiusPathIdx := 0;
     nextRadiusPathIdx := 0;
     base := fNumPath - 1;
     
     // handle last element
     for cnt := 1 to radius do
     begin
          fPath[fNumPath].i := fPath[base].i + cnt;
          fPath[fNumPath].j := fPath[base].j;
          inc(fNumPath);
     end;

     baseI := -1;
     
     // build up new window from the previous path
     for cnt := 0 to fNumPath - 1 do
     begin
          // check if we already caught that particular i
          if fPath[cnt].i = baseI then
             continue;

          baseI := fPath[cnt].i;
          baseJ := fPath[cnt].j;

          // find the min max in the given radius
          minJ := Max(0, baseJ - radius);
          maxJ := baseJ + radius;
          
          // find previous 
          while (fPath[prevRadiusPathIdx].i < baseI - radius) do
                inc(prevRadiusPathIdx);
          // find next
          while (nextRadiusPathIdx < fNumPath - 1) and (fPath[nextRadiusPathIdx].i <= baseI + radius) do
                inc(nextRadiusPathIdx);
          // find boundaries
          for pathCnt := prevRadiusPathIdx to nextRadiusPathIdx do
          begin
               minj := Max(0, Min( fPath[pathCnt].j - radius, minJ) );
               maxj := Max( fPath[pathCnt].j + radius, maxJ);
          end;

          // add to window list
          for i := 2*basei to 2*basei + 1 do
          begin
               if Length(fWindow) < Result + 2*(maxJ - minJ + 1) then
                  SetLength(fWindow, Min(2*Length(fWindow), Length(fWindow) + 1000));
          
               for j := 2*minJ to 2*maxJ do
               begin
                    fWindow[Result].i := i + 1;        // per convention we add one
                    fWindow[Result].j := j + 1;
                    inc(Result);
               end;
          end;

          // remove the ones that are too much
          while (Result > 0) and ( (fWindow[Result - 1].i > inXLen) or (fWindow[Result - 1].j > inYLen) ) do
                dec(Result);
     end;
end;

end.