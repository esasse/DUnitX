{***************************************************************************}
{                                                                           }
{           DUnitX                                                          }
{                                                                           }
{           Copyright (C) 2012 Vincent Parrett                              }
{                                                                           }
{           vincent@finalbuilder.com                                        }
{           http://www.finalbuilder.com                                     }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit DUnitX.TestResult;

interface

uses
  System.Timespan,
  DUnitX.TestFramework,
  DUnitX.WeakReference,
  DUnitX.InternalInterfaces,
  SysUtils;

{$I DUnitX.inc}

type
  TDUnitXTestResult = class(TInterfacedObject, ITestResult)
  private
    //Keeping message as the user passed message. Not used for internal functionality like exception messages.
    FMessage : string;
    FResultType : TTestResultType;
    FTest : IWeakReference<ITestInfo>;
  protected
    function GetMessage: string;
    function GetResult: Boolean;
    function GetResultType: TTestResultType;
    function GetTest: ITestInfo;
    function GetTestStartTime : TDateTime;
    function GetTestEndTime : TDateTime;
    function GetTestDuration : TTimeSpan;
  public
    constructor Create(const ATestInfo : ITestInfo; const AType : TTestResultType; const AMessage : string = '');
  end;

  TDUnitXTestError = class(TDUnitXTestResult, ITestError)
  private
    FStackTrace : string;
    FExceptionClass : ExceptClass;
    FExceptionMessage : string;
    FExceptionAddress : Pointer;
  protected
    function GetExceptionClass : ExceptClass;
    function GetExceptionLocationInfo : string;
    function GetExceptionAddressInfo : string;
    function GetExceptionMessage : string;
  public
    constructor Create(const ATestInfo : ITestInfo; const AType : TTestResultType; const AThrownException: Exception; const Addrs: Pointer; const AMessage : string = '');reintroduce;
  end;

implementation

uses
  Winapi.Windows;

{ TDUnitXTestResult }

function PtrToStr(p: Pointer): string;
begin
   Result := Format('%p', [p])
end;

function PointerToLocationInfo(Addrs: Pointer): string;
begin
  //TODO: Expand out to support JEDI JCL and MADSHI if they are present.
  Result := ''
end;

function PointerToAddressInfo(Addrs: Pointer): string;
begin
  //TODO: Expand out to support JEDI JCL and MADSHI if they are present.
  if Assigned(Addrs) then
    Result := '$' + PtrToStr(Addrs)
  else
    Result := 'n/a';
end;

constructor TDUnitXTestResult.Create(const ATestInfo : ITestInfo; const AType: TTestResultType; const AMessage: string);
begin
  FTest := TWeakReference<ITestInfo>.Create(ATestInfo);

  FResultType := AType;
  FMessage := AMessage;
end;

function TDUnitXTestResult.GetMessage: string;
begin
  result := FMessage;
end;

function TDUnitXTestResult.GetResult: Boolean;
begin
   result := GetResultType = TTestResultType.Success;
end;

function TDUnitXTestResult.GetResultType: TTestResultType;
begin
  result := FResultType;
end;

function TDUnitXTestResult.GetTest: ITestInfo;
begin
  if FTest.IsAlive then
    result := FTest.Data
  else
    result := nil;
end;

function TDUnitXTestResult.GetTestDuration: TTimeSpan;
begin
  if FTest.IsAlive then
    Result := FTest.Data.GetTestDuration
  else
    Result := TTimeSpan.Zero;
end;

function TDUnitXTestResult.GetTestEndTime: TDateTime;
begin
  if FTest.IsAlive then
    Result := FTest.Data.GetTestEndTime
  else
    Result := 0;
end;

function TDUnitXTestResult.GetTestStartTime: TDateTime;
begin
  if FTest.IsAlive then
    Result := FTest.Data.GetTestStartTime
  else
    Result := 0;
end;

{ TDUnitXTestError }

constructor TDUnitXTestError.Create(const ATestInfo : ITestInfo; const AType: TTestResultType; const AThrownException: Exception; const Addrs: Pointer; const AMessage: string = '');
begin
  inherited Create(ATestInfo, AType, AMessage);

  FExceptionClass := ExceptClass(AThrownException.ClassType);

  FExceptionMessage := AMessage + AThrownException.Message;
  FExceptionAddress := Addrs;

  //TODO: Expand out to support JEDI JCL and MADSHI if they are present.
  FStackTrace := AThrownException.StackTrace;
end;

function TDUnitXTestError.GetExceptionAddressInfo: string;
begin
  Result := PointerToAddressInfo(FExceptionAddress);
end;

function TDUnitXTestError.GetExceptionClass: ExceptClass;
begin
  result := FExceptionClass;
end;

function TDUnitXTestError.GetExceptionLocationInfo: string;
begin
  Result := PointerToLocationInfo(FExceptionAddress);
end;

function TDUnitXTestError.GetExceptionMessage: string;
begin
  Result := FExceptionMessage;
end;

end.