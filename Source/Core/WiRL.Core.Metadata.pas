{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2021 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Core.Metadata;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.Rtti,
  System.TypInfo,

  WiRL.http.Core,
  WiRL.http.Accept.MediaType,
  WiRL.Core.Attributes,
  WiRL.Core.Exceptions,
  WiRL.Core.Declarations,
  WiRL.Core.Registry;

type
  TWiRLProxyResource = class;

  TWiRLProxyBase = class
  protected
    FProcessed: Boolean;
    FName: string;
    FRemarks: string;
    FSummary: string;
  public
    procedure Process(); virtual;

    property Name: string read FName write FName;
    property Summary: string read FSummary write FSummary;
    property Remarks: string read FRemarks write FRemarks;
  end;

  TWiRLProxyFilter = class(TWiRLProxyBase)
  private
    FAttribute: TCustomAttribute;
    FFilterType: TClass;
  public
    constructor Create(AAttribute: TCustomAttribute);
    procedure Process(); override;
  public
    property FilterType: TClass read FFilterType;
  end;

  TWiRLProxyFilters = class(TObjectList<TWiRLProxyFilter>);

  TWiRLProxyParameter = class(TWiRLProxyBase)
  private
    FParam: TRttiParameter;
    FAttributes: TArray<TCustomAttribute>;
    FInjected: Boolean;
    FValue: string;
    FKind: TMethodParamType;
    FName: string;
    FRest: Boolean;
    procedure ProcessAttributes;
  public
    constructor Create(AParam: TRttiParameter);

    procedure Process(); override;
  public
    property Rest: Boolean read FRest write FRest;
    property Name: string read FName write FName;
    property Kind: TMethodParamType read FKind write FKind;
    property Value: string read FValue write FValue;
    property Injected: Boolean read FInjected write FInjected;

    property RttiParam: TRttiParameter read FParam write FParam;
    property Attributes: TArray<TCustomAttribute> read FAttributes write FAttributes;
  end;

  TWiRLProxyParameters = class(TObjectList<TWiRLProxyParameter>);

  TWiRLProxyMethodResult = class(TWiRLProxyBase)
  private
    FRttiObject: TRttiType;
    FResultType: TTypeKind;
    FIsClass: Boolean;
    FIsRecord: Boolean;
    FIsSingleton: Boolean;
    FIsProcedure: Boolean;
    FIsArray: Boolean;
    FIsSimple: Boolean;
  public
    constructor Create(AResultType: TRttiType);

    procedure Process(); override;
    procedure SetAsSingleton;
  public
    property IsProcedure: Boolean read FIsProcedure;

    property ResultType: TTypeKind read FResultType;
    property IsClass: Boolean read FIsClass;
    property IsRecord: Boolean read FIsRecord;
    property IsArray: Boolean read FIsArray;
    property IsSimple: Boolean read FIsSimple;
    property IsSingleton: Boolean read FIsSingleton;
  end;

  TWiRLProxyMethodAuth = class(TWiRLProxyBase)
  private
    FDenyAll: Boolean;
    FRoles: TStringArray;
    FPermitAll: Boolean;
    FHasAuth: Boolean;
  public
    procedure Process(); override;

    procedure SetPermitAll;
    procedure SetDenyAll;
    procedure SetRoles(ARoles: TStrings);
  public
    property HasAuth: Boolean read FHasAuth;
    property DenyAll: Boolean read FDenyAll;
    property PermitAll: Boolean read FPermitAll;
    property Roles: TStringArray read FRoles;
  end;

  TWiRLProxyMethod = class(TWiRLProxyBase)
  private
    FResource: TWiRLProxyResource;
    FRttiMethod: TRttiMethod;
    FHttpVerb: string;
    FPath: string;
    FConsumes: TMediaTypeList;
    FProduces: TMediaTypeList;
    FMethodResult: TWiRLProxyMethodResult;
    FAsync: Boolean;
    FRest: Boolean;
    FIsFunction: Boolean;
    FAuth: TWiRLProxyMethodAuth;
    FFilters: TWiRLProxyFilters;
    FAllAttributes: TArray<TCustomAttribute>;
    FStatus: TWiRLHttpStatus;
    FParams: TWiRLProxyParameters;
    FName: string;
    FAuthHandler: Boolean;

    procedure ProcessAttributes;
    procedure ProcessParams;
  public
    constructor Create(AResource: TWiRLProxyResource; ARttiMethod: TRttiMethod);
    destructor Destroy; override;

    procedure Process(); override;

    function NewParam(AParam: TRttiParameter): TWiRLProxyParameter;

    function HasFilter(AAttribute: TCustomAttribute): Boolean;
  public
    property Rest: Boolean read FRest;
    property Name: string read FName;
    property Path: string read FPath;
    property Async: Boolean read FAsync;
    property Auth: TWiRLProxyMethodAuth read FAuth;
    property AuthHandler: Boolean read FAuthHandler;
    property IsFunction: Boolean read FIsFunction;
    property HttpVerb: string read FHttpVerb write FHttpVerb;
    property MethodResult: TWiRLProxyMethodResult read FMethodResult;
    property Consumes: TMediaTypeList read FConsumes;
    property Produces: TMediaTypeList read FProduces;
    property Filters: TWiRLProxyFilters read FFilters;
    property Status: TWiRLHttpStatus read FStatus write FStatus;
    property Params: TWiRLProxyParameters read FParams write FParams;

    property AllAttributes: TArray<TCustomAttribute> read FAllAttributes;
    property RttiObject: TRttiMethod read FRttiMethod;
  end;

  TWiRLProxyMethods = class(TObjectList<TWiRLProxyMethod>);

  TWiRLProxyResource = class(TWiRLProxyBase)
  private
    FContext: TWiRLResourceRegistry;
    FResourceClass: TClass;
    FConstructor: TWiRLConstructorProxy;
    FPath: string;
    FAuth: Boolean;
    FRttiType: TRttiType;
    FMethods: TWiRLProxyMethods;
    FProduces: TMediaTypeList;
    FConsumes: TMediaTypeList;
    FFilters: TWiRLProxyFilters;

    procedure ProcessAttributes;
    procedure ProcessMethods;
  public
    constructor Create(const AName: string; AContext: TWiRLResourceRegistry);
    destructor Destroy; override;
  public
    procedure Process(); override;

    function CreateInstance: TObject;

    function MatchProduces(AMethod: TWiRLProxyMethod; AMediaType: TMediaType): Boolean;
    function MatchConsumes(AMethod: TWiRLProxyMethod; AMediaType: TMediaType): Boolean;
    function IsSwagger(const ASwaggerResource: string): Boolean;
    function NewMethod(AMethod: TRttiMethod; const AVerb: string): TWiRLProxyMethod;
    function GetSanitizedPath: string;
  public
    property Path: string read FPath;
    property Auth: Boolean read FAuth write FAuth;
    property Methods: TWiRLProxyMethods read FMethods;
    property Produces: TMediaTypeList read FProduces;
    property Consumes: TMediaTypeList read FConsumes;
    property Filters: TWiRLProxyFilters read FFilters;

    // Rtti-based properties (to be removed)
    // Introduce: ClassName, UnitName
    property ResourceClass: TClass read FResourceClass write FResourceClass;
  end;

  //TWiRLProxyResources = class(TObjectList<TWiRLProxyResource>);
  TWiRLProxyResources = class(TObjectDictionary<string, TWiRLProxyResource>);

  TWiRLProxyApplication = class(TWiRLProxyBase)
  private
    FContext: TWiRLResourceRegistry;
    FResources: TWiRLProxyResources;
  public
    constructor Create(AContext: TWiRLResourceRegistry);
    destructor Destroy; override;
    procedure ProcessResources;
  public
    procedure Process(); override;
    function NewResource(const AName: string): TWiRLProxyResource;
    function GetResource(const AName: string): TWiRLProxyResource;

    property Resources: TWiRLProxyResources read FResources write FResources;
  end;

  TWiRLAPIDoc = class(TWiRLProxyApplication)

  end;

  TWiRLProxyContext = record
  private
    FProxy: TWiRLProxyApplication;
    FXMLDocFolder: string;
  public
    property Proxy: TWiRLProxyApplication read FProxy write FProxy;
    property XMLDocFolder: string read FXMLDocFolder write FXMLDocFolder;
  end;

  TWiRLProxyEngine = class
  protected
    FContext: TWiRLProxyContext;
  public
    constructor Create(AContext: TWiRLProxyContext); virtual;
  end;


implementation

uses
  WiRL.Core.Auth.Resource,
  WiRL.http.URL,
  WiRL.Rtti.Utils;


function IsFilter(AAttribute: TCustomAttribute): Boolean;
begin
  Result := False;

  // If the Attribute is NameBinding
  if AAttribute is NameBindingAttribute then
    Result := True;

  // If the Attribute has a NameBinding attribute
  if not Result then
    if TRttiHelper.HasAttribute<NameBindingAttribute>(
      TRttiHelper.Context.GetType(AAttribute.ClassType)) then
      Result := True;
end;

{ TWiRLProxyResource }

constructor TWiRLProxyResource.Create(const AName: string; AContext: TWiRLResourceRegistry);
begin
  FName := AName;
  FContext := AContext;

  FMethods := TWiRLProxyMethods.Create(True);
  FFilters := TWiRLProxyFilters.Create(True);

  FContext.TryGetValue(AName, FConstructor);
  if not Assigned(FConstructor) then
    EWiRLServerException.CreateFmt('Resource [%s] not found', [AName]);

  FResourceClass := FConstructor.TypeTClass;

  FRttiType := TRttiHelper.Context.GetType(FResourceClass);

  // If a Resource inherits from Add TWiRLAuth* add a SecurityDefinition
  if FResourceClass.InheritsFrom(TWiRLAuthBasicResource) then
    FAuth := True;
end;

destructor TWiRLProxyResource.Destroy;
begin
  FFilters.Free;
  FMethods.Free;
  inherited;
end;

function TWiRLProxyResource.CreateInstance: TObject;
begin
  Result := FConstructor.ConstructorFunc();
end;

function TWiRLProxyResource.GetSanitizedPath: string;
begin
  Result := Path.Trim(['/']);
end;

function TWiRLProxyResource.IsSwagger(const ASwaggerResource: string): Boolean;
begin
  if SameText(FName.Trim(['/']), ASwaggerResource.Trim(['/'])) then
    Result := True
  else
    Result := False;
end;

function TWiRLProxyResource.MatchConsumes(AMethod: TWiRLProxyMethod; AMediaType: TMediaType): Boolean;
begin
  Result := False;

  if AMethod.Consumes.Empty then
    Exit(True);

  if AMethod.Consumes.IsWildCard then
    Exit(True);

  if AMethod.Consumes.Contains(AMediaType) then
    Exit(True);
end;

function TWiRLProxyResource.MatchProduces(AMethod: TWiRLProxyMethod; AMediaType: TMediaType): Boolean;
begin
  Result := False;

  if AMethod.Produces.Empty or AMediaType.IsWildcard then
    Exit(True);

  // It's a procedure, so no "Produces" mechanism
  if not AMethod.IsFunction then
    Exit(True);

  // Tries to match the Produces MediaType
  if AMethod.Produces.Contains(AMediaType) then
    Exit(True);


  // If the method result it's an object there is no Produces let the MBWs choose the output
  if AMethod.Produces.IsWildCard and (AMethod.MethodResult.IsClass or AMethod.MethodResult.IsRecord) then
    Exit(True);
end;

function TWiRLProxyResource.NewMethod(AMethod: TRttiMethod; const AVerb: string): TWiRLProxyMethod;
begin
  Result := TWiRLProxyMethod.Create(Self, AMethod);
  Result.HttpVerb := AVerb;
  FMethods.Add(Result);
end;

procedure TWiRLProxyResource.Process;
begin
  inherited;

  ProcessAttributes;
  ProcessMethods;
  //FSummary := FindReadXMLDoc();

  FProcessed := True;
end;

procedure TWiRLProxyResource.ProcessAttributes;
var
  LAttribute: TCustomAttribute;
  LMediaList: TArray<string>;
  LMedia: string;
begin
  // Global loop to retrieve and process ALL attributes at once
  for LAttribute in FRttiType.GetAttributes do
  begin
    // Path Attribute
    if LAttribute is PathAttribute then
      FPath := PathAttribute(LAttribute).Value

    // Consumes Attribute
    else if LAttribute is ConsumesAttribute then
    begin
      LMediaList := ConsumesAttribute(LAttribute).Value.Split([',']);

      for LMedia in LMediaList do
        FConsumes.Add(TMediaType.Create(LMedia));
    end

    // Produces Attribute
    else if LAttribute is ProducesAttribute then
    begin
      LMediaList := ProducesAttribute(LAttribute).Value.Split([',']);

      for LMedia in LMediaList do
        FProduces.Add(TMediaType.Create(LMedia));
    end

    // Filters
    else if IsFilter(LAttribute) then
    begin
      FFilters.Add(TWiRLProxyFilter.Create(LAttribute));
    end
  end;
end;

procedure TWiRLProxyResource.ProcessMethods;
var
  LResourceMethod: TRttiMethod;
  LHttpVerb: string;
  LResMeth: TWiRLProxyMethod;
begin
  // Loop on every method of the current resource object
  for LResourceMethod in FRttiType.GetMethods do
  begin

    LHttpVerb := '';
    TRttiHelper.HasAttribute<HttpMethodAttribute>(LResourceMethod,
      procedure (AAttr: HttpMethodAttribute)
      begin
        LHttpVerb := AAttr.ToString.ToLower;
      end
    );

    // This method is a REST handler
    if not LHttpVerb.IsEmpty then
    begin
      LResMeth := NewMethod(LResourceMethod, LHttpverb);
      LResMeth.Process();
    end;
  end;
end;

{ TWiRLProxyMethod }

constructor TWiRLProxyMethod.Create(AResource: TWiRLProxyResource; ARttiMethod: TRttiMethod);
begin
  FResource := AResource;
  FRttiMethod := ARttiMethod;
  FConsumes := TMediaTypeList.Create;
  FProduces := TMediaTypeList.Create;
  FFilters := TWiRLProxyFilters.Create(True);
  FAuth := TWiRLProxyMethodAuth.Create;
  FStatus := TWiRLHttpStatus.Create;
  FParams := TWiRLProxyParameters.Create(True);
  FMethodResult := TWiRLProxyMethodResult.Create(FRttiMethod.ReturnType);
  FName := FRttiMethod.Name;

  FIsFunction := Assigned(FRttiMethod.ReturnType);

  //ProcessAttributes;
  //ProcessParams;
end;

destructor TWiRLProxyMethod.Destroy;
begin
  FParams.Free;
  FStatus.Free;
  FAuth.Free;
  FFilters.Free;
  FMethodResult.Free;
  FConsumes.Free;
  FProduces.Free;
  inherited;
end;

function TWiRLProxyMethod.HasFilter(AAttribute: TCustomAttribute): Boolean;
var
  LFilter: TWiRLProxyFilter;
begin
  // Any non decorated filter should be used
  if not Assigned(AAttribute) then
    Exit(True);
  Result := False;
  for LFilter in FFilters do
  begin
    if AAttribute is LFilter.FilterType then
    begin
      Result := True;
      Break;
    end;
  end;

  if not Result then
    for LFilter in FResource.Filters do
    begin
      if AAttribute is LFilter.FilterType then
      begin
        Result := True;
        Break;
      end;
    end;

end;

function TWiRLProxyMethod.NewParam(AParam: TRttiParameter): TWiRLProxyParameter;
begin
  Result := TWiRLProxyParameter.Create(AParam);
  FParams.Add(Result);
end;

procedure TWiRLProxyMethod.Process;
begin
  inherited;

  ProcessAttributes;
  ProcessParams;

  FProcessed := True;
end;

procedure TWiRLProxyMethod.ProcessAttributes;
var
  LAttribute: TCustomAttribute;
  LStatus: ResponseStatusAttribute;
  LMediaList: TArray<string>;
  LMedia: string;
begin
  FRest := False;

  // Global loop to retrieve and process all attributes at once
  for LAttribute in FRttiMethod.GetAttributes do
  begin
    // Add the attribute in the AllAttribute array
    FAllAttributes := FAllAttributes + [LAttribute];

    // Method HTTP Method
    if LAttribute is HttpMethodAttribute then
    begin
      FHttpVerb := HttpMethodAttribute(LAttribute).ToString;
      FRest := True;
    end

    // Method Path
    else if LAttribute is PathAttribute then
      FPath := PathAttribute(LAttribute).Value

    // Method is Async
    else if LAttribute is AsyncResponseAttribute then
      FAsync := True

    // Method Result is Singleton
    else if LAttribute is SingletonAttribute then
      FMethodResult.SetAsSingleton

    // Method Authorization
    else if LAttribute is RolesAllowedAttribute then
      FAuth.SetRoles(RolesAllowedAttribute(LAttribute).Roles)
    else if LAttribute is PermitAllAttribute then
      FAuth.SetPermitAll
    else if LAttribute is DenyAllAttribute then
      FAuth.SetDenyAll

    // Method that handles Authorization (via CustomAttribute)
    else if LAttribute is BasicAuthAttribute then
      FAuthHandler := True

    // Method Consumes
    else if LAttribute is ConsumesAttribute then
    begin
      LMediaList := ConsumesAttribute(LAttribute).Value.Split([',']);

      for LMedia in LMediaList do
        FConsumes.Add(TMediaType.Create(LMedia));
    end

    // Method Produces
    else if LAttribute is ProducesAttribute then
    begin
      LMediaList := ProducesAttribute(LAttribute).Value.Split([',']);

      for LMedia in LMediaList do
        FProduces.Add(TMediaType.Create(LMedia));
    end

    // Filters
    else if IsFilter(LAttribute) then
    begin
      FFilters.Add(TWiRLProxyFilter.Create(LAttribute));
    end

    // ResponseRedirection
    else if LAttribute is ResponseRedirectionAttribute then
    begin
      LStatus := (LAttribute as ResponseStatusAttribute);
      FStatus.Code := LStatus.Code;
      FStatus.Reason := LStatus.Reason;
      FStatus.Location := (LStatus as ResponseRedirectionAttribute).Location;
    end

    // ResponseStatus
    else if LAttribute is ResponseStatusAttribute then
    begin
      LStatus := (LAttribute as ResponseStatusAttribute);
      FStatus.Code := LStatus.Code;
      FStatus.Reason := LStatus.Reason;
    end

  end;
end;

procedure TWiRLProxyMethod.ProcessParams;
var
  LParam: TRttiParameter;
  LWiRLParameter: TWiRLProxyParameter;
begin
  for LParam in FRttiMethod.GetParameters do
  begin
    LWiRLParameter := NewParam(LParam);
    LWiRLParameter.Process();
    if not LWiRLParameter.Rest then
      raise EWiRLServerException.CreateFmt(
        'Non annotated params [%s] are not allowed. Method-> [%s.%s]',
        [LWiRLParameter.Name, FResource.ResourceClass.ClassName, FName]
      );
  end;
end;

{ TWiRLProxyMethodResult }

constructor TWiRLProxyMethodResult.Create(AResultType: TRttiType);
begin
  FRttiObject := AResultType;
end;

procedure TWiRLProxyMethodResult.Process;
begin
  inherited;

  if Assigned(FRttiObject) then
  begin
    FResultType := FRttiObject.TypeKind;
    case FResultType of
      tkClass:  FIsClass := True;
      tkRecord: FIsRecord := True;
      tkArray,
      tkDynArray: FIsArray := True;
    else
      FIsSimple := True;
    end;
  end
  else
    FIsProcedure := True;

  FProcessed := True;
end;

procedure TWiRLProxyMethodResult.SetAsSingleton;
begin
  FIsSingleton := True;
end;

{ TWiRLProxyMethodAuth }

procedure TWiRLProxyMethodAuth.Process;
begin
  inherited;

  FProcessed := True;
end;

procedure TWiRLProxyMethodAuth.SetDenyAll;
begin
  FHasAuth := True;
  FDenyAll := True;
  FPermitAll := False;
end;

procedure TWiRLProxyMethodAuth.SetPermitAll;
begin
  FHasAuth := True;
  FDenyAll := False;
  FPermitAll := True;
end;

procedure TWiRLProxyMethodAuth.SetRoles(ARoles: TStrings);
begin
  FHasAuth := True;
  FDenyAll := False;
  FPermitAll := False;
  FRoles := ARoles.ToStringArray;
end;

{ TWiRLProxyFilter }

constructor TWiRLProxyFilter.Create(AAttribute: TCustomAttribute);
begin
  FAttribute := AAttribute;
  FFilterType := FAttribute.ClassType;
end;

procedure TWiRLProxyFilter.Process;
begin
  inherited;

  FProcessed := True;
end;

{ TWiRLProxyParameter }

constructor TWiRLProxyParameter.Create(AParam: TRttiParameter);
begin
  FParam := AParam;
  FName := FParam.Name;
  ProcessAttributes;
end;

procedure TWiRLProxyParameter.Process;
begin
  inherited;

  ProcessAttributes;
  FProcessed := True;
end;

procedure TWiRLProxyParameter.ProcessAttributes;
var
  LAttr: TCustomAttribute;
begin
  FAttributes := FParam.GetAttributes;

  for LAttr in FAttributes do
  begin
    // Loop only inside attributes that define how to read the parameter
    if not ( (LAttr is ContextAttribute) or (LAttr is MethodParamAttribute) ) then
      Continue;

    FRest := True;

    // context injection
    if (LAttr is ContextAttribute) and (FParam.ParamType.IsInstance) then
    begin
      FInjected := True;
      Continue;
      //if ContextInjectionByType(FParam, LContextValue) then
        //Exit(LContextValue);
    end;

    // Param Kind
    if LAttr is PathParamAttribute then
      Kind := TMethodParamType.Path
    else if LAttr is QueryParamAttribute then
      Kind := TMethodParamType.Query
    else if LAttr is FormParamAttribute then
      Kind := TMethodParamType.Form
    else if LAttr is HeaderParamAttribute then
      Kind := TMethodParamType.Header
    else if LAttr is CookieParamAttribute then
      Kind := TMethodParamType.Cookie
    else if LAttr is BodyParamAttribute then
      Kind := TMethodParamType.Body
    else if LAttr is FormDataParamAttribute then
      Kind := TMethodParamType.FormData
    else if LAttr is MultipartAttribute then
      Kind := TMethodParamType.MultiPart;

    // Param Name
    FName := (LAttr as MethodParamAttribute).Value;
    if (FName = '') or (LAttr is BodyParamAttribute) then
      FName := FParam.Name;
  end;
end;

{ TWiRLProxyApplication }

constructor TWiRLProxyApplication.Create(AContext: TWiRLResourceRegistry);
begin
  FResources := TWiRLProxyResources.Create([doOwnsValues]);
  FContext := AContext;
end;

destructor TWiRLProxyApplication.Destroy;
begin
  FResources.Free;
  inherited;
end;

function TWiRLProxyApplication.GetResource(const AName: string): TWiRLProxyResource;
begin
  if not FResources.TryGetValue(AName, Result) then
    raise EWiRLNotFoundException.CreateFmt('Resource [%s] not found', [AName]);
end;

function TWiRLProxyApplication.NewResource(const AName: string): TWiRLProxyResource;
begin
  Result := TWiRLProxyResource.Create(AName, FContext);
  FResources.Add(AName, Result);
end;

procedure TWiRLProxyApplication.Process;
begin
  inherited;

  ProcessResources;
  FProcessed := True;
end;

procedure TWiRLProxyApplication.ProcessResources;
var
  LResourceName: string;
  LResource: TWiRLProxyResource;
begin
  // Loop on every resource of the application
  for LResourceName in FContext.Keys do
  begin
    LResource := NewResource(LResourceName);
    LResource.Process();
  end;
end;

{ TWiRLProxyEngine }

constructor TWiRLProxyEngine.Create(AContext: TWiRLProxyContext);
begin
  FContext := AContext;
end;

{ TWiRLProxyBase }

procedure TWiRLProxyBase.Process;
begin
  if FProcessed then
    raise EWiRLServerException.Create(Self.ClassName + ' already processed');
end;

end.