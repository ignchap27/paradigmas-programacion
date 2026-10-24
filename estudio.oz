fun {NewBook InitTitle InitPages}
    CellTitle = {NewCell InitTitle}
    CellPages = {NewCell InitPages}
    fun {Attributes}
        attributes(title:CellTitle pages:CellPages)
    end
    fun {Title}
        @CellTitle
    end
    fun {Pages}
        @CellPages
    end
in
    object(attributes:{Attributes} title:Title pages:Pages)
    end


fun {ComposeSimple Obj1 Obj2}
   AttrsFusionados = {Adjoin Obj2.attributes Obj1.attributes}
   General = {Adjoin Obj2 Obj1}
in
   {Record.adjoinAt General attributes AttrsFusionados}
end


fun {RemoveDuplicates Lista}
   Resultado = {NewCell nil}
in
   for O in Lista do
      YaEsta = {NewCell false}
   in
      for Existente in @Resultado do
         if Existente == O then
            YaEsta := true
         end
      end
      if @YaEsta == false then
         Resultado := O | @Resultado
      end
   end
   @Resultado
end

fun {ExplicitComposition Objs}
    Resultado = {NewCell object(attributes:attributes())}
    ListaLimpia = {RemoveDuplicates Objs}
    in
    for O in ListaLimpia do
        
        Resultado := {ComposeSimple @Resultado O}
        end
    @Resultado
    end
        
        
fun {AllMethodNames Objs}
    Resultado = {NewCell nil}
    in 
        for O in Objs do
            for F in {Arity O} do
                if F \= attributes andthen {Member F @Resultado} == false then
                    Resultado := F | @Resultado
                end
            end
        end
    @Resultado
end

fun {AllImplementations Objs}
    Resultado = {NewCell nil}
    in 
        for O in Objs do
            if {HasFeature O F} then
                Resultado := {Record.get O F} | @Resultado
            end
        @Resultado
        end

fun {ExplicitCompositionWithMethods Objs}
    Unicos = {RemoveDuplicates Objs}
    Nombres = {AllMethodNames Unicos}
    Resultado = {NewCell {ExplicitComposition Unicos}}
    in
        for F in Nombres do
            Resultado := {Record.adjoinAt @Resultado F {AllImplementations Unicos}}
            end
        @Resultado
        end

fun {Car InBrand InSpeed}
    CellBrand = {NewCell InBrand}
    CellSpeed = {NewCell InSpeed}
    fun {Brand}
        @CellBrand
    end
    fun {Speed}
        @CellSpeed
    end
    proc {Acelerate Incremet}
        CellSpeed := @CellSpeed + Incremet
    end
    fun {Attributes} attributes(brand:CellBrand speed:CellSpeed) end
in
    object(attributes:{Attributes} brand:Brand speed:Speed acelerate:Acelerate)
end

fun {Radio InVolume}
    CellVolume = {NewCell InVolume}
    fun {Volume}
        @CellVolume
    end
    proc {SetVolume NewVal}
        CellVolume := NewVal
    end
    fun {Attributes} attributes(volume:CellVolume) end
in
    object(attributes:{Attributes} volume:Volume setVolume:SetVolume)
end

fun {ComposeSimple Obj1 Obj2}
    AttrsFusionados = {Adjoin Obj2.attributes Obj1.attributes}
    General = {Adjoin Obj2 Obj1}
    in 
        {Record.adjoinAt General attributes AttrsFusionados}
    end

MiCar = {Car "Toyota" 0}
MiRadio = {Radio 10}
SmartCar = {ComposeSimple MiCar MiRadio}
{SmartCar.acelerate 50}
{SmartCar.setVolume 20}

fun {Dog InName}
    CellName = {NewCell InName}
    fun {Attributes} attributes(name:CellName) end
    fun {Describe}
        "Dog named " # @CellName
    end
in
    object(attributes:{Attributes} describe:Describe)
end

fun {Robot InName}
    CellName = {NewCell InName}
    fun {Attributes} attributes(name:CellName) end
    fun {Describe}
        "Robot named " # @CellName
    end
in
    object(attributes:{Attributes} describe:Describe)
end

MiPerro = {Dog "Fido"}
MiRobot = {Robot "R2D2"}
MixedThing = {ComposeSimple MiPerro MiRobot}


proc {Dispatch Obj Selector Param Index}
    Imps = Obj.Selector
in
    if Index =< {Length Imps} then
        OldNext = @NextThunk
    in
        NextThunk := proc {$} {Dispatch Obj Selector Params Index+1} end
        {{Nth Impls Index} Params}
        NextThunk := OldNext
    end
   proc {NextFunction}
   {@NextThunk}
end
end

''' EXAMEN DE PRUEBA REALIZARLO '''
fun {Sensor InLocation InReading}
    CellLocation = {NewCell InLocation}
    CellReading = {NewCell InReading}
    fun {Attributes} attributes(location:CellLocation reading:CellReading) end
    fun {Reading}
        @CellReading
    end
   fun {Location}
        @CellLocation
    end
    proc {UpdateReading NewReading}
        CellReading := NewReading
    end
in
    object(attributes:{Attributes} reading:Reading location:Location updateReading:UpdateReading)
    end

fun {Alarm}
    CellActive = {NewCell False}
    fun {Attributes} attributes(active:CellActive) end
    fun {IsActive}
        @CellActive
    end
    proc {Trigger}
        CellActive := True
    end

'''Punto 2'''

fun {ExplicitComposition Objs}
Resultado = {NewCell object(attributes:attributes())}
ListaLimpia = {RemoveDuplicates Objs}
in
for O in ListaLimpia do
Resultado := {ComposeSimple @Resultado O}
end
@Resultado
end

'''Punto 3'''
Si, es una metafuncion ya que no requiere saber nada de los objetos que se le pasan, solo requiere que tengan el mismo metodo y lo ejecuta.

'''Punto 4'''
fun {ExplicitCompositionPoly Objs}
    Unicos = {RemoveDuplicates Objs}
    Nombres = {AllMethodNames Unicos}
    Resultado = {NewCell {ExplicitComposition Unicos}}
in
    for F in Nombres do
    Resultado := {Record.adjoinAt @Resultado F {AllImplementations Unicos
    F}}
end
@Resultado
end

'''Punto 5'''
proc {Dispatch Obj Selector Params Index}
    Impls = Obj.Selector
in
    if Index =< {Length Impls} then
    {{Nth Impls Index} Params}
    end
end

'''Punto 6'''
MiSensor = {Sensor "Living Room" 10}
MiAlarma = {Alarm}
MiSistema = {ExplicitCompositionPoly [MiSensor MiAlarma]}


""" Parcial de prueba 2"""

fun {Note InText}
    CellText = {NewCell InText}
    CellPinned = {NewCell false}
    fun {Attributes} attributes(text:CellText pinned:CellPinned) end
    fun {Text}
        @CellText
    end
    fun {IsPinned}
        @CellPinned
    end
    end
    proc {Pin}
        CellPinned := true
    end
in
    object(attributes:{Attributes} text:Text isPinned:IsPinned pin:Pin)
end

fun {Tag InLabel}
    CellLabel = {NewCell InLabel}
    fun {Attributes} attributes(label:CellLabel) end
    fun {Label}
        @CellLabel
    end
in
    object(attributes:{Attributes} label:Label)
end

fun {ExplicitComposition Objs}
    Resultado = {NewCell object(attributes:attributes())}
    ListaLimpia = {RemoveDuplicates Objs}
    in
        for O in ListaLimpia do
            Resultado := {ComposeSimple @Resultado O}
        end
    @Resultado
    end



fun {FieldNames Obj}
     Resultado = {NewCell nil}
in
   for F in {Arity Obj} do
      if F \= attributes then
         Resultado := F | @Resultado
      end
   end
   @Resultado
end


fun {ExplicitCompositionPoly Objs}
    Unicos = {RemoveDuplicates Objs}
    Nombres = {AllMethodNames Unicos}
    Resultado = {NewCell {ExplicitComposition Unicos}}
in
    for F in Nombres do
    Resultado := {Record.adjoinAt @Resultado F {AllImplementations Unicos
    F}}
end
@Resultado
end

proc {Dispatch Obj Selector Params Index}
Impls = Obj.Selector
in
if Index =< {Length Impls} then
{{Nth Impls Index} Params}
end
end

% ===== TASK 1: Object definition =====
fun {Vehicle InModel InMileage}
   ModelCell   = {NewCell InModel}
   MileageCell = {NewCell InMileage}
   fun {Attributes} attributes(model:ModelCell mileage:MileageCell) end
   fun {Model}   @ModelCell   end
   fun {Mileage} @MileageCell end
   proc {Display}                      % "displays" = efecto, no valor -> proc
      {Browse "Vehicle"}
      {Browse "Model:"#@ModelCell}
      {Browse "Mileage:"#@MileageCell}
   end
in
   object(attributes:{Attributes} model:Model mileage:Mileage display:Display)
end

fun {Driver InName InVehicle}
   NameCell    = {NewCell InName}
   VehicleCell = {NewCell InVehicle}
   fun {Attributes} attributes(name:NameCell vehicle:VehicleCell) end
   fun {DriverName}    @NameCell    end
   fun {DriverVehicle} @VehicleCell end     % ojo: nombre exacto del enunciado
   proc {Display}
      {Browse "Driver"}
      {Browse "Name:"#@NameCell}
   end
in
   object(attributes:{Attributes} driverName:DriverName driverVehicle:DriverVehicle display:Display)
end


% ===== TASK 2: ExplicitComposition =====
fun {ComposeSimple O1 O2}                 % gana O1 en choques
   A = {Adjoin O2.attributes O1.attributes}
   G = {Adjoin O2 O1}
in
   {Record.adjoinAt G attributes A}       % "adjoinAt", sin la "t" de más
end

fun {RemoveDuplicates L}
   R = {NewCell nil}
in
   for O in L do
      Ya = {NewCell false}
   in
      for Ex in @R do if Ex==O then Ya:=true end end
      if @Ya==false then R:=O|@R end
   end
   @R
end

fun {ExplicitComposition Objs}
   R = {NewCell object(attributes:attributes())}   % paréntesis, no llaves
   L = {RemoveDuplicates Objs}
in
   for O in L do R := {ComposeSimple @R O} end
   @R
end


% ===== TASK 3: Conceptual =====
% Sí, es meta-función: no ejecuta el comportamiento normal de un objeto,
% sino que MANIPULA/reconstruye la ESTRUCTURA (el record) de los objetos que recibe.


% ===== TASK 4: ExplicitCompositionPoly =====
fun {AllMethodNames Objs}                 % mismo nombre SIEMPRE, sin typos
   R = {NewCell nil}
in
   for O in Objs do
      for F in {Arity O} do
         if F \= attributes andthen {Member F @R} == false then   % "andthen" junto
            R := F|@R
         end
      end
   end
   @R
end

fun {AllImplementations Objs F}
   R = {NewCell nil}
in
   for O in Objs do
      if {HasFeature O F} then R := O.F|@R end
   end
   @R
end

fun {ExplicitCompositionPoly Objs}        % "Poly", sin mayúscula rara
   U = {RemoveDuplicates Objs}
   N = {AllMethodNames U}
   R = {NewCell {ExplicitComposition U}}
in
   for F in N do
      R := {Record.adjoinAt @R F {AllImplementations U F}}
   end
   @R
end


% ===== TASK 5: Dispatch (SIN índice todavía, como pedía el enunciado) =====
proc {Dispatch Obj Selector Param}
   Impls = Obj.Selector
in
   {{Nth Impls 1} Param}     % en esta versión, siempre la primera implementación
end


% ===== TASK 6: extender Dispatch con índice + NextFunction =====
NextThunk = {NewCell proc {$} skip end}

proc {NextFunction}
   {@NextThunk}              % SE EJECUTA con llaves, no solo @
end

proc {DispatchNext Obj Selector Param Idx}
   Impls = Obj.Selector
in
   if Idx =< {Length Impls} then          % "Length", sin typo
      Old = @NextThunk
   in
      NextThunk := proc {$} {DispatchNext Obj Selector Param Idx+1} end
      {{Nth Impls Idx} Param}
      NextThunk := Old
   end
end

fun {Light}
    BrightnessCell = {NewCell 0}
    IsOnCell = {NewCell false}
    fun {Attributes}attributes( brightness:BrightnessCell isOn:IsOnCell) end
    fun {Brightness}
        @BrightnessCell
    end
    proc {TurnsOn}
        IsOnCell := true
    end
    proc {SetBrightness NewVal}
        BrightnessCell := NewVal
    end
in
    object(attributes:{Attributes} brightness:Brightness turnsOn:TurnsOn setBrightness:SetBrightness)
end

fun {Thermostat InTemperature}
    TemperatureCell ={NewCell InTemperature}
    fun {Attributes}attribute( temperature:TemperatureCell) end
    fun {Temperature}
        @TemperatureCell
    end
    proc {SetTemperature NewVal}
        TemperatureCell := NewVal
    end
in
    object(attributes:{Attributes} temperature:Temperature setTemperature:SetTemperature)
end

fun {RemoveDuplicates L}
    R= {NewCell nil}
in
    for O in L do 
        ya = {NewCell false}
    in
        for Ex in @R do 
            if Ex == O then
                ya := true
            end
        end
        if @ya == false then
            R := O|@R 
        end
    end
    @R 
end

fun {ComposeSimple O1 O2}
    A = {Adjoin O2.attributes O1.attributes}
    G = {Adjoin O2 O1}
    in
    {Record.adjoinAt G attributes A}
    end

fun {ExplicitComposition Objs}
    R= {NewCell object(attributes:attributes())}
    L = {RemoveDuplicates Objs}
in
    for O in L do 
        R := {ComposeSimple @R O}
    end
@R
end

removeduplicates no es una meta funcion porque solo lee y ejecuta en el objeto no lo camiba en forma ni nada

fun {AllImplementations Objs F}
   R = {NewCell nil}
in
   for O in Objs do
      if {HasFeature O F} then R := O.F|@R end
   end
   @R
end

fun {ExplicitCompositionPoly Objs}        % "Poly", sin mayúscula rara
   U = {RemoveDuplicates Objs}
   N = {AllMethodNames U}
   R = {NewCell {ExplicitComposition U}}
in
   for F in N do
      R := {Record.adjoinAt @R F {AllImplementations U F}}
   end
   @R
end

proc {Dispatch Obj Selector Params Index}
Impls = Obj.Selector
in
if Index =< {Length Impls} then
{{Nth Impls Index} Params}
end
end

NextThunk = {NewCell proc {$} skip end}

proc {NextFunction}
   {@NextThunk}              % SE EJECUTA con llaves, no solo @
end

proc {DispatchNext Obj Selector Param Idx}
   Impls = Obj.Selector
in
   if Idx =< {Length Impls} then          % "Length", sin typo
      Old = @NextThunk
   in
      NextThunk := proc {$} {DispatchNext Obj Selector Param Idx+1} end
      {{Nth Impls Idx} Param}
      NextThunk := Old
   end
end

fun {Playlist InName InCount}
    NameCell = {NewCell InName}
    CountCell = {NewCell InCount}
    fun {Attributes}atributes(name:NameCell count:CountCell) end
    fun {Name}
        @NameCell
    end
    fun {CurrentCount}
        @CountCell
    end
    proc {Played}
        CountCell := @CountCell + 1
    end
in
    object(attributes:{Attributes} name:Name currentCount:CurrentCount played:Played)
end

fun {Curator InName}
    NameCell = {NewCell InName}
    fun {Attributes}atributes(name:NameCell) end
    proc {Show}
        {Browse "Curated by" # @NameCell}
    end
in 
    object(attributes:{Attributes} show:Show)
end

fun {ComposeSimple O1 O2}
    A = {Adjoin O2.attributes O1.attributes}
    G = {Adjoin O2 O1}
    in
    {Record.adjoinAt G attributes A}
    end

fun {RemoveDuplicates L}
    R= {NewCell nil}
in
    for O in L do 
        ya = {NewCell false}
    in
        for Ex in @R do 
            if Ex == O then
                ya := true
            end
        end
        if @ya == false then
            R := O|@R 
        end
    end
    @R 
end

fun {ExplicitComposition Objs}
    R= {NewCell object(attributes:attributes())}
    L = {RemoveDuplicates Objs}
in
    for O in L do 
        R := {ComposeSimple @R O}
    end
@R
end

la funcion de explicitcomposition esta considera caomo metafuncion ua qye cambia la esctrucutra del objeto al combinarlos y poner el primero y combinarlos

seria con implicito por tanto cambiaria a sollo tener que mantener records y ocmpararlos apra asi construir el objeto

fun {AllMethodNames Objs}
    R = {NewCell nil}
in
    for O in Objs do
        for F in {Arity O} do
            if F /= attributes andthen {Member F@R} == false then
                R := F|@R
            end
        end
    end
    @R 
end

fun {ExplicitCompositionPoly Objs}        % "Poly", sin mayúscula rara
   U = {RemoveDuplicates Objs}
   N = {AllMethodNames U}
   R = {NewCell {ExplicitComposition U}}
in
   for F in N do
      R := {Record.adjoinAt @R F {AllImplementations U F}}
   end
   @R
end

proc {Dispatch Obj Selector Param}
   Impls = Obj.Selector
in
   {{Nth Impls 1} Param}     % en esta versión, siempre la primera implementación
end


NextThunk = {NewCell proc {$} skip end}

proc {NextFunction}
   {@NextThunk}              % SE EJECUTA con llaves, no solo @
end

proc {DispatchNext Obj Selector Param Idx}
   Impls = Obj.Selector
in
   if Idx =< {Length Impls} then          % "Length", sin typo
      Old = @NextThunk
   in
      NextThunk := proc {$} {DispatchNext Obj Selector Param Idx+1} end
      {{Nth Impls Idx} Param}
      NextThunk := Old
   end
end

fun {MenuItem InName InPrice}
    PriceCell = {NewCell InPrice}
    NameCell = {NewCell InName}
    fun {Attributes}attribures(name:NameCell price:PriceCell) end
    fun {Price}
        @PriceCell
    end
    proc {NewPrice NewValue}
        PriceCell := NewValue
    end
    fun {Display}
        {Browse "Name " # @NameCell}
        {Browse "Descripcion " # @PriceCell}
    end
in
    object(attribute:{Attributes} price:Price newPrice:NewPrice display:Display)
end

fun {ImplicitComposition Objs}
    fun {Get Selector}
        R = {NewCell unit}
    in
        for O in Objs do 
            if @R == unit andthen {HasFeature O Selector} then
                R := O.selector
            end
        end
        @R 
    end in
        object(objects:Objs get:Get)
    end

Para mi si seria una metafuncion puesto que va llamadno lo que necesita y cambiando la estructura del objeto segun las neceidades dadas por el selector

fun {ExplicitComposition Objs}
    R= {NewCell object(attributes:attributes())}
    L = {RemoveDuplicates Objs}
in
    for O in L do 
        R := {ComposeSimple @R O}
    end
@R
end

fun {ExplicitCompositionPoly Objs}        % "Poly", sin mayúscula rara
   U = {RemoveDuplicates Objs}
   N = {AllMethodNames U}
   R = {NewCell {ExplicitComposition U}}
in
   for F in N do
      R := {Record.adjoinAt @R F {AllImplementations U F}}
   end
   @R
end

Lo que pasaria es que se tendrian que tener tantas copias del objeto como sean necesras para poder usar cada metodo en los distintos contextos

proc {Dispatch Obj Selector Params Index}
Impls = Obj.Selector
in
if Index =< {Length Impls} then
{{Nth Impls Index} Params}
end
end


proc {NextFunction}
   {@NextThunk}              % SE EJECUTA con llaves, no solo @
end

proc {DispatchNext Obj Selector Param Idx}
   Impls = Obj.Selector
in
   if Idx =< {Length Impls} then          % "Length", sin typo
      Old = @NextThunk
   in
      NextThunk := proc {$} {DispatchNext Obj Selector Param Idx+1} end
      {{Nth Impls Idx} Param}
      NextThunk := Old
   end
end

