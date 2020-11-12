﻿# DataSet to Delphi Code

![ Delphi Support ](https://img.shields.io/badge/Delphi%20Support-%20XE8%20..%2010.4-blue.svg)
![ version ](https://img.shields.io/badge/version-%201.5-yellow.svg)

## Overview

DataSet Generator is a component that generates a Delphi code using any dataset provided as an input parameter. Component output is a function which creates and populates in-memory dataset according to structure and content of the provided dataset. The main reason for building this component was ability to generate quickly fake datasets for unit testing purposes.

## Generator usage

DataSet Generator is used to create a fake in-memory dataset to bypass usage of SQL datasets in a test code. This scenario is quite straightforward: 

### (Step 1) Create a new fake factory

Find a production dataset which need to be faked and run generator, the easiest way is to call one of its class methods:

```pas
uses
  Comp.Generator.DataSetCode;
```
```pas
begin
  aDataSet := fDataSetFactory.ConstructSelectDataset(
    SQL_SELECT_CustomerOrders_FromOneMonth, 
    [aYear, aMonth] );
  // ------------------------------------
  // injected generator call:
  TDSGenerator.GenerateAndSaveToFile(
    aDataSet,
    'Fake.CustomerOrders.pas');
  // ------------------------------------
  fOrdersView.SetMasterDataset(aDataSet);
end;
```

Sample code containing a fake factory method generated by this component you can find bellow in the next section.

Developer can generate whole unit or only factory method. It is possible to customize some generator options, but int that case it's required to construct new object of class TDSGenerator, sets this objects properties (options) and call its `Execute` method.

### (Step 2) Use generated fake function

In the sample code above was used a view object: `fOrdersView` of the class `TOrdersView`. This view class uses a dataset injected via method `SetMasterDataset` to calculate a date (period of the year) impact on a total monthly sale value. Because above code is dependent on a SQL connection and a SQL database (dataset provided by `fDataSetFactory`) you need a fake to put a method `TOrdersView.GetCurrentImpact` into unit test harness:

```pas
procedure TestOrdersView.Setup;
begin
  fOwner := TComponent.Create;
  fOrderModelMock := TMock<IOrdersModel>.Create;
  fOrdersView := TOrdersView.Create(fOrderModelMock);
  // ...
end;

procedure TestOrdersView.Test_CalculateCurrentImpact;
var
  aFakeOrdersDataSet: TDataSet;
  actualImpact: Extended;
begin
  aFakeOrdersDataSet := CreateDataSet(fOwner);
  fOrdersView.SetMasterDataset(aFakeOrdersDataSet);
  
  actualImpact := fOrdersView.GetCurrentImpact;

  Assert.AreEqual(0.054, actualImpact, 0.0000001);
end;
```

## Sample generated fake factory

```pas
function CreateDataSet (aOwner: TComponent): TDataSet;
var
  ds: TFDMemTable;
begin
  ds := TFDMemTable.Create(AOwner);
  with ds do
  begin
    FieldDefs.Add('Id', ftInteger);
    FieldDefs.Add('Name', ftWideString, 30);
    FieldDefs.Add('RegistrationDate', ftDate);
    FieldDefs.Add('Balance', ftFloat);
    FieldDefs.Add('Budget', ftCurrency);
    CreateDataSet;
  end;
  ds.AppendRecord([1, 'Team integration', EncodeDate(2019, 09, 16), 1.2, 1200]);
  ds.AppendRecord([2, 'Progress retrospective', Null, Null, 950]);
  ds.First;
  Result := ds;
end;
```

## TDSGenerator methods

### `TDSGenerator` class methods:

| Class method | Description |
| --- | --- |
| `GenerateAsString` | Receives `aDataSet` as a parameter and generates fake dataset factory function as the result |
| `GenerateAndSaveToFile` | Receives `aDataSet` an `aFileName`, generates whole unit containing factory function and save it into file |
| `GenerateAndSaveToClipboard` | Receives `aDataSet`, generates fake dataset factory function and copies generated code to the clipboard |

All class methods are using default set of options:
- `IdentationText` = two spaces 
- `AppendMode` = append one data row in multiple lines
- `DataSetType` = fake based on FireDAC memory table

### Generate using `Execute` method

Although class methods are the fastest way to generate fake dataset, in some cases it's better to use object method `Execute`. To call object method you have to construct object of class `TDSGenerator`, like in the sample bellow:

```pas
aGenerator := TDSGenerator.Create(Self);  // owner
aGenerator.AppendMode := amSinglelineAppends;
aGenerator.GeneratorMode := genFunction;
aGenerator.IndentationText := #9;  // one TAB
aGenerator.Execute;
Memo1.Lines := aGenerator.Code;
aGenerator.Free;
```

In this code not only generator is constructed and executed, but also generator's options are defined: GeneratorMode, AppendMode and IndentationText. This options are used during code generation. Generated code is available through the `Code` property (internal string list) after execution.

## TDSGenerator options

| Option | Definition and description |
| --- | --- |
| `IndentationText` | `String` Used as a code indentation text (defined text is used a an one level of the indentation) |
| `GeneratorMode` | `TGeneratorMode` Decides which section of code are generated when using Execute command. Values: `genStructure`, `genAppend`, `genFunction`, `genUnit`. |
| `DataSetType` | `TDataSetType` Decides which in-memory dataset component is used as a fake. Values: `dstFDMemTable`, `dstClientDataSet`. |
| `AppendMode` | `TAppendMode` Defines Code format of append data section (described bellow). Values: `amMultilineAppends`, `amSinglelineAppends`, `amAppendRowArray`. |
| `MaxRows` | `Integer` Maximum number of a rows from input dataset which are used to generate append section *(default value = `100`)* |
| `UnitName` | `String` Used as unit name when the whole unit is generated, (not used in other generator modes) |
| `RightMargin` | `Integer` Defines width of generated code - only applies to generation of string literals including multiline string literals |

### Option: `AppendMode`

What is difference between two values of AppendMode: multi-line append and single-line append?

Generator is able to create more compact or more detailed append section for each of a data rows. With single-line / compact mode generator is creating one append using `ds.AppendRecord` method (where `ds: TDataSet`). This method receiving all row's data in one open array of variants, what makes this code more compact. 

Sample code generated in single-line mode. `AppendMode` = `amSinglelineAppends`:

```pas
ds.AppendRecord([1, 'Team integration', EncodeDate(2019, 09, 16), 1.2, 1200]);
```

In a second multi-line / detailed  mode generator is creating code with multiple calls: `ds.Append`, `ds.FieldByName`, ..., `ds.FieldByName`. and `ds.Post`. This mode is allow to fill data in some selected fields, fill blob fields and keeps better control over the code.

Sample code generated in multi-line mode. `AppendMode` = `amMultilineAppends`:

```pas
ds.Append;
ds.FieldByName('Id').Value := 1;
ds.FieldByName('Name').Value := 'Team integration';
ds.FieldByName('RegistrationDate').Value := EncodeDate(2019, 09, 16);
ds.FieldByName('Balance')Value := 1.2;
ds.FieldByName('Budget').Value := 1200;
ds.Post;
```

New AppendMode was implemented in version 1.5 (`amAppendRowArray`). In that mode this component is generating two dimensional array with all the rows inserted in one statement:

```pas
ds.AppendRows([
  [1, ''FirstRow''],
  [2, ''MiddleRow''],
  [3, ''LastRow'']
);
```

## Fakes vs mocks

Testing objects which using datasets internally is challenging. Many teams gave up with introduction unit tests to their projects because of such dependencies.

Delphi event driven / component approach makes this task even more challenging. Why? For two reasons: (1) many not fully compatible dataset implementation and (2) implementation of business code in dataset events. Datasets can have many very specific implementation like (BDE, dbExpress, FireDAC and many others) and production code can highly coupled to the only one implementation. Developers can use universal, general and quite powerful `TDataSet` class, but usually production code is very dependent on the one implementation. Furthermore injecting production code into dataset events looks like very productive approach and many times was suggested as winning approach, but within the time such code is really difficult to understand, maintain and put into test harness (unit testing process).

According to automated test practices there are 3 ways of replace or remove heavy dependencies:
1. Mocks 
   - simplified implementation of dependency which can be injected instead of a heavy class (DB access, network communication, etc.)
   - developer is able to verify is a particual method was called, what parameters was provided or how many times it was called (developer can define and check expectations)
1. Stubs 
   - more advanced then mocks, in addition to expectation developer can define a behavior - what values methods are returning with which parameters 
1. Fakes 
   - replacement implementation of the dependency, including almost full functionality of object, boy working in-memory.

Using dataset fakes developers can much easier decouple code from actual implementation and put production code into test harness. In long term fakes can be refactored into stubs and then into fakes. It will be much more easy and much less stressful to provide complex refactoring after delivering unit test safety net for the production code.
