unit Form.Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,

  System.SysUtils,
  System.Variants,
  System.Classes,
  Spring.Collections,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Actions, Vcl.ActnList,
  {-}
  Logic.Scorecards,
  Data.DataModule1;

type
  TForm1 = class(TForm)
    gboxConnect: TGroupBox;
    btnConnect: TButton;
    gboxScorecards: TGroupBox;
    lbxMonths: TListBox;
    Panel1: TPanel;
    Label1: TLabel;
    ActionList1: TActionList;
    actDatabaseConnect: TAction;
    MemoTest: TMemo;
    procedure actDatabaseConnectExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbxMonthsClick(Sender: TObject);
  private
    fDataModule1: TDataModule1;
    procedure FillListBoxWithMonths(const aListBox: TListBox);
    procedure ShowData(const aEmployeeScores: IReadOnlyCollection<TEmployeeScore>);
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  Spring;


procedure TForm1.actDatabaseConnectExecute(Sender: TObject);
begin
  fDataModule1.Connect();
  FillListBoxWithMonths(lbxMonths);
end;

procedure TForm1.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  gboxScorecards.Visible := fDataModule1.IsConnected();
  actDatabaseConnect.Enabled := not fDataModule1.IsConnected();
end;

procedure TForm1.FillListBoxWithMonths(const aListBox: TListBox);
var
  activeMonths: IList<Tuple<String, Word, Word>>;
  aMonth: Tuple<String, Word, Word>;
begin
  activeMonths := fDataModule1.GetActiveMonths();
  aListBox.Clear;
  for aMonth in activeMonths do
  begin
    aListBox.Items.Insert(0, aMonth.Value1);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  gboxScorecards.Visible := False;
  gboxScorecards.Align := alClient;
  fDataModule1 := TDataModule1.Create( Application);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  actDatabaseConnect.Execute;
end;

procedure TForm1.ShowData(const aEmployeeScores: IReadOnlyCollection<TEmployeeScore>);
var
  employeeScore: TEmployeeScore;
begin
  MemoTest.Clear;
  for employeeScore in aEmployeeScores do
  begin
    MemoTest.Lines.Add(Format('%s (%d) - %d orders',
    [employeeScore.fEmployeeName, employeeScore.fEmployeeId, employeeScore.fOrderCount]));
  end;
end;

procedure TForm1.lbxMonthsClick(Sender: TObject);
var
  strMonth: string;
  aYear: word;
  aMonth: word;
  aScorecards: TScorecards;
  aEmployeeScores: IReadOnlyCollection<TEmployeeScore>;
begin
  if lbxMonths.ItemIndex<0 then
    Exit;
  strMonth := lbxMonths.Items[lbxMonths.ItemIndex];
  aYear := strMonth.Substring(0,4).ToInteger();
  aMonth := strMonth.Substring(5,2).ToInteger();
  aScorecards := TScorecards.Create(aYear, aMonth);
  aEmployeeScores := aScorecards.GenerateData(fDataModule1);
  ShowData(aEmployeeScores);
end;

end.
