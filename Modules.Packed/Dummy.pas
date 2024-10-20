﻿
//*****************************************************************************************************\\
// Copyright (©) Sun Serega ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\
// Copyright (©) Sun Serega ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Данный код распространяется с лицензией Unlicense
// Подробнее в файле LICENSE или тут:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\

///Внутренний модуль POCGL для тестирования кодогенераторов
unit Dummy;

{$zerobasedstrings}

interface

uses System;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

type
  
  {$region Особые типы}
  
  ///Базовый тип перечислений
  EnumBase = UInt32;
  
  ///Абстрактное понятие загрузчика адресов функций api
  DummyLoader = abstract class
    
    ///Фунция получения адреса функции api
    public function GetProcAddress(name: string): IntPtr; abstract;
    
  end;
  
  {$endregion Особые типы}
  
  {$region Вспомогательные типы}
  
  ///
  Multichoise1 = record
    public val: EnumBase;
    public constructor(val: EnumBase) := self.val := val;
    
    public static property Choise1_1_InpFlat:      Multichoise1 read new Multichoise1($0001);
    public static property Choise1_2_InpArr:       Multichoise1 read new Multichoise1($0002);
    public static property Choise1_3_OtpFlat:      Multichoise1 read new Multichoise1($0003);
    public static property Choise1_4_OtpArr:       Multichoise1 read new Multichoise1($0004);
    public static property Choise1_5_OtpStaticArr: Multichoise1 read new Multichoise1($0005);
    public static property Choise1_6_OtpString:    Multichoise1 read new Multichoise1($0006);
    
    public function ToString: string; override;
    begin
      if Choise1_1_InpFlat = self then
        Result := 'Choise1_1_InpFlat' else
      if Choise1_2_InpArr = self then
        Result := 'Choise1_2_InpArr' else
      if Choise1_3_OtpFlat = self then
        Result := 'Choise1_3_OtpFlat' else
      if Choise1_4_OtpArr = self then
        Result := 'Choise1_4_OtpArr' else
      if Choise1_5_OtpStaticArr = self then
        Result := 'Choise1_5_OtpStaticArr' else
      if Choise1_6_OtpString = self then
        Result := 'Choise1_6_OtpString' else
        Result := $'Multichoise1[{self.val}]';
    end;
    
  end;
  
  ///
  Multichoise2 = record
    public val: EnumBase;
    public constructor(val: EnumBase) := self.val := val;
    
    public static property Choise2_1_InpFlat: Multichoise2 read new Multichoise2($0001);
    public static property Choise2_2_InpArr:  Multichoise2 read new Multichoise2($0002);
    
    public function ToString: string; override;
    begin
      if Choise2_1_InpFlat = self then
        Result := 'Choise2_1_InpFlat' else
      if Choise2_2_InpArr = self then
        Result := 'Choise2_2_InpArr' else
        Result := $'Multichoise2[{self.val}]';
    end;
    
  end;
  
  {$endregion Вспомогательные типы}
  
  {$region Подпрограммы ядра}
  
  {$ifndef DEBUG}
  [System.Security.SuppressUnmanagedCodeSecurity]
  {$endif DEBUG}
  [PCUNotRestore]
  ///
  dum = static class
    
    // added in dum1.0
    private static procedure ntv_f1NoParam_1;
      external 'dummy.dll' name 'f1NoParam';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f1NoParam :=
      ntv_f1NoParam_1;
    
    // added in dum1.0
    private static function ntv_f1NoParamResult_1: UIntPtr;
      external 'dummy.dll' name 'f1NoParamResult';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f1NoParamResult: UIntPtr :=
      ntv_f1NoParamResult_1;
    
    // added in dum1.0
    private static procedure ntv_f2ParamString_1(s: IntPtr);
      external 'dummy.dll' name 'f2ParamString';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f2ParamString(s: IntPtr) :=
      ntv_f2ParamString_1(s);
    
    // added in dum1.0
    private static procedure ntv_f2ParamStringRO_1(s: IntPtr);
      external 'dummy.dll' name 'f2ParamStringRO';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f2ParamStringRO(s: string);
    begin
      var s_str_ptr := Marshal.StringToHGlobalAnsi(s);
      try
        ntv_f2ParamStringRO_1(s_str_ptr);
      finally
        Marshal.FreeHGlobal(s_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f2ParamStringRO(s: IntPtr) :=
      ntv_f2ParamStringRO_1(s);
    
    // added in dum1.0
    private static function ntv_f3ResultString_1: IntPtr;
      external 'dummy.dll' name 'f3ResultString';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f3ResultString: string;
    begin
      var Result_str_ptr := ntv_f3ResultString_1;
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    
    // added in dum1.0
    private static function ntv_f3ResultStringRO_1: IntPtr;
      external 'dummy.dll' name 'f3ResultStringRO';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f3ResultStringRO: string :=
      Marshal.PtrToStringAnsi(ntv_f3ResultStringRO_1);
    
    // added in dum1.0
    private static procedure ntv_f4Generic_1(var data: Byte);
      external 'dummy.dll' name 'f4Generic';
    private static procedure ntv_f4Generic_2(data: pointer);
      external 'dummy.dll' name 'f4Generic';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4Generic<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        f4Generic(data[0]) else
        f4Generic(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4Generic<T>(var data: T); where T: record;
    begin
      ntv_f4Generic_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4Generic(data: pointer) :=
      ntv_f4Generic_2(data);
    
    // added in dum1.0
    private static procedure ntv_f4GenericRO_1(var data: Byte);
      external 'dummy.dll' name 'f4GenericRO';
    private static procedure ntv_f4GenericRO_2(data: pointer);
      external 'dummy.dll' name 'f4GenericRO';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericRO<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        f4GenericRO(data[0]) else
        f4GenericRO(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericRO<T>(var data: T); where T: record;
    begin
      ntv_f4GenericRO_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericRO(data: pointer) :=
      ntv_f4GenericRO_2(data);
    
    // added in dum1.0
    private static procedure ntv_f4GenericWOVarArg_1(var data: Byte);
      external 'dummy.dll' name 'f4GenericWOVarArg';
    private static procedure ntv_f4GenericWOVarArg_2(data: pointer);
      external 'dummy.dll' name 'f4GenericWOVarArg';
    private [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure temp_f4GenericWOVarArg_1<T>(var data: T); where T: record;
    begin
      ntv_f4GenericWOVarArg_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericWOVarArg<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        temp_f4GenericWOVarArg_1(data[0]) else
        temp_f4GenericWOVarArg_1(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericWOVarArg(data: pointer) :=
      ntv_f4GenericWOVarArg_2(data);
    
    // added in dum1.0
    private static procedure ntv_f4GenericWOVarArgRO_1(var data: Byte);
      external 'dummy.dll' name 'f4GenericWOVarArgRO';
    private static procedure ntv_f4GenericWOVarArgRO_2(data: pointer);
      external 'dummy.dll' name 'f4GenericWOVarArgRO';
    private [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure temp_f4GenericWOVarArgRO_1<T>(var data: T); where T: record;
    begin
      ntv_f4GenericWOVarArgRO_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericWOVarArgRO<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        temp_f4GenericWOVarArgRO_1(data[0]) else
        temp_f4GenericWOVarArgRO_1(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f4GenericWOVarArgRO(data: pointer) :=
      ntv_f4GenericWOVarArgRO_2(data);
    
    // added in dum1.0
    private static procedure ntv_f5Arrrrrray_1(a: pointer);
      external 'dummy.dll' name 'f5Arrrrrray';
    private static procedure ntv_f5Arrrrrray_2(var a: IntPtr);
      external 'dummy.dll' name 'f5Arrrrrray';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5Arrrrrray(a: array of array of array of array of array of UIntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<UIntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                SetLength(a_tmp_el_3[a_ind_3], a_len_4);
                var a_tmp_el_4 := a_tmp_el_3[a_ind_3];
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_org_el_5 := a_org_el_4[a_ind_4];
                  if (a_org_el_5=nil) or (a_org_el_5.Length=0) then continue;
                  var a_len_5 := a_org_el_5.Length;
                  var a_tmp_el_5_ptr := Marshal.AllocHGlobal(a_len_5 * a_el_sz);
                  a_tmp_el_4[a_ind_4] := a_tmp_el_5_ptr;
                  for var a_ind_5 := 0 to a_len_5-1 do
                  begin
                    var a_tmp_el_5_ptr_typed: ^UIntPtr := a_tmp_el_5_ptr.ToPointer;
                    a_tmp_el_5_ptr_typed^ := a_org_el_5[a_ind_5];
                    a_tmp_el_5_ptr := a_tmp_el_5_ptr + a_el_sz;
                  end;
                end;
              end;
            end;
          end;
        end;
        f5Arrrrrray(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do if arr_el3<>nil then
               foreach var arr_el4 in arr_el3 do Marshal.FreeHGlobal(arr_el4);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5Arrrrrray(a: array of array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                var a_tmp_el_4_ptr := Marshal.AllocHGlobal(a_len_4 * a_el_sz);
                a_tmp_el_3[a_ind_3] := a_tmp_el_4_ptr;
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_tmp_el_4_ptr_typed: ^IntPtr := a_tmp_el_4_ptr.ToPointer;
                  a_tmp_el_4_ptr_typed^ := a_org_el_4[a_ind_4];
                  a_tmp_el_4_ptr := a_tmp_el_4_ptr + a_el_sz;
                end;
              end;
            end;
          end;
        end;
        f5Arrrrrray(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do Marshal.FreeHGlobal(arr_el3);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5Arrrrrray(a: array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              var a_tmp_el_3_ptr := Marshal.AllocHGlobal(a_len_3 * a_el_sz);
              a_tmp_el_2[a_ind_2] := a_tmp_el_3_ptr;
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_tmp_el_3_ptr_typed: ^IntPtr := a_tmp_el_3_ptr.ToPointer;
                a_tmp_el_3_ptr_typed^ := a_org_el_3[a_ind_3];
                a_tmp_el_3_ptr := a_tmp_el_3_ptr + a_el_sz;
              end;
            end;
          end;
        end;
        f5Arrrrrray(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do Marshal.FreeHGlobal(arr_el2);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5Arrrrrray(a: array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            var a_tmp_el_2_ptr := Marshal.AllocHGlobal(a_len_2 * a_el_sz);
            a_tmp_el_1[a_ind_1] := a_tmp_el_2_ptr;
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_tmp_el_2_ptr_typed: ^IntPtr := a_tmp_el_2_ptr.ToPointer;
              a_tmp_el_2_ptr_typed^ := a_org_el_2[a_ind_2];
              a_tmp_el_2_ptr := a_tmp_el_2_ptr + a_el_sz;
            end;
          end;
        end;
        ntv_f5Arrrrrray_2(a_temp_arr[0]);
      finally
         foreach var arr_el1 in a_temp_arr do Marshal.FreeHGlobal(arr_el1);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5Arrrrrray(var a: IntPtr) :=
      ntv_f5Arrrrrray_2(a);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5Arrrrrray(a: pointer) :=
      ntv_f5Arrrrrray_1(a);
    
    // added in dum1.0
    private static procedure ntv_f5ArrrrrrayOfGeneric_1(a: pointer);
      external 'dummy.dll' name 'f5ArrrrrrayOfGeneric';
    private static procedure ntv_f5ArrrrrrayOfGeneric_2(var a: IntPtr);
      external 'dummy.dll' name 'f5ArrrrrrayOfGeneric';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfGeneric<T>(a: array of array of array of array of array of T); where T: record;
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<T>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                SetLength(a_tmp_el_3[a_ind_3], a_len_4);
                var a_tmp_el_4 := a_tmp_el_3[a_ind_3];
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_org_el_5 := a_org_el_4[a_ind_4];
                  if (a_org_el_5=nil) or (a_org_el_5.Length=0) then continue;
                  var a_len_5 := a_org_el_5.Length;
                  var a_tmp_el_5_ptr := Marshal.AllocHGlobal(a_len_5 * a_el_sz);
                  a_tmp_el_4[a_ind_4] := a_tmp_el_5_ptr;
                  for var a_ind_5 := 0 to a_len_5-1 do
                  begin
                    var a_tmp_el_5_ptr_typed: ^T := a_tmp_el_5_ptr.ToPointer;
                    a_tmp_el_5_ptr_typed^ := a_org_el_5[a_ind_5];
                    a_tmp_el_5_ptr := a_tmp_el_5_ptr + a_el_sz;
                  end;
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfGeneric(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do if arr_el3<>nil then
               foreach var arr_el4 in arr_el3 do Marshal.FreeHGlobal(arr_el4);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfGeneric(a: array of array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                var a_tmp_el_4_ptr := Marshal.AllocHGlobal(a_len_4 * a_el_sz);
                a_tmp_el_3[a_ind_3] := a_tmp_el_4_ptr;
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_tmp_el_4_ptr_typed: ^IntPtr := a_tmp_el_4_ptr.ToPointer;
                  a_tmp_el_4_ptr_typed^ := a_org_el_4[a_ind_4];
                  a_tmp_el_4_ptr := a_tmp_el_4_ptr + a_el_sz;
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfGeneric(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do Marshal.FreeHGlobal(arr_el3);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfGeneric(a: array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              var a_tmp_el_3_ptr := Marshal.AllocHGlobal(a_len_3 * a_el_sz);
              a_tmp_el_2[a_ind_2] := a_tmp_el_3_ptr;
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_tmp_el_3_ptr_typed: ^IntPtr := a_tmp_el_3_ptr.ToPointer;
                a_tmp_el_3_ptr_typed^ := a_org_el_3[a_ind_3];
                a_tmp_el_3_ptr := a_tmp_el_3_ptr + a_el_sz;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfGeneric(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do Marshal.FreeHGlobal(arr_el2);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfGeneric(a: array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            var a_tmp_el_2_ptr := Marshal.AllocHGlobal(a_len_2 * a_el_sz);
            a_tmp_el_1[a_ind_1] := a_tmp_el_2_ptr;
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_tmp_el_2_ptr_typed: ^IntPtr := a_tmp_el_2_ptr.ToPointer;
              a_tmp_el_2_ptr_typed^ := a_org_el_2[a_ind_2];
              a_tmp_el_2_ptr := a_tmp_el_2_ptr + a_el_sz;
            end;
          end;
        end;
        ntv_f5ArrrrrrayOfGeneric_2(a_temp_arr[0]);
      finally
         foreach var arr_el1 in a_temp_arr do Marshal.FreeHGlobal(arr_el1);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfGeneric(var a: IntPtr) :=
      ntv_f5ArrrrrrayOfGeneric_2(a);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfGeneric(a: pointer) :=
      ntv_f5ArrrrrrayOfGeneric_1(a);
    
    // added in dum1.0
    private static procedure ntv_f5ArrrrrrayOfString_1(s: pointer);
      external 'dummy.dll' name 'f5ArrrrrrayOfString';
    private static procedure ntv_f5ArrrrrrayOfString_2(var s: IntPtr);
      external 'dummy.dll' name 'f5ArrrrrrayOfString';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfString(s: array of array of array of array of string);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of array of array of array of IntPtr;
      try
        begin
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            SetLength(s_tmp_el_1[s_ind_1], s_len_2);
            var s_tmp_el_2 := s_tmp_el_1[s_ind_1];
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_org_el_3 := s_org_el_2[s_ind_2];
              if (s_org_el_3=nil) or (s_org_el_3.Length=0) then continue;
              var s_len_3 := s_org_el_3.Length;
              SetLength(s_tmp_el_2[s_ind_2], s_len_3);
              var s_tmp_el_3 := s_tmp_el_2[s_ind_2];
              for var s_ind_3 := 0 to s_len_3-1 do
              begin
                var s_org_el_4 := s_org_el_3[s_ind_3];
                if (s_org_el_4=nil) or (s_org_el_4.Length=0) then continue;
                var s_len_4 := s_org_el_4.Length;
                SetLength(s_tmp_el_3[s_ind_3], s_len_4);
                var s_tmp_el_4 := s_tmp_el_3[s_ind_3];
                for var s_ind_4 := 0 to s_len_4-1 do
                begin
                  var s_org_el_5 := s_org_el_4[s_ind_4];
                  if (s_org_el_5=nil) or (s_org_el_5.Length=0) then continue;
                  s_tmp_el_4[s_ind_4] := Marshal.StringToHGlobalAnsi(s_org_el_5);
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfString(s_temp_arr);
      finally
         foreach var arr_el1 in s_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do if arr_el3<>nil then
               foreach var arr_el4 in arr_el3 do Marshal.FreeHGlobal(arr_el4);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfString(s: array of array of array of array of IntPtr);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of array of array of IntPtr;
      try
        begin
          var s_el_sz := Marshal.SizeOf&<IntPtr>;
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            SetLength(s_tmp_el_1[s_ind_1], s_len_2);
            var s_tmp_el_2 := s_tmp_el_1[s_ind_1];
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_org_el_3 := s_org_el_2[s_ind_2];
              if (s_org_el_3=nil) or (s_org_el_3.Length=0) then continue;
              var s_len_3 := s_org_el_3.Length;
              SetLength(s_tmp_el_2[s_ind_2], s_len_3);
              var s_tmp_el_3 := s_tmp_el_2[s_ind_2];
              for var s_ind_3 := 0 to s_len_3-1 do
              begin
                var s_org_el_4 := s_org_el_3[s_ind_3];
                if (s_org_el_4=nil) or (s_org_el_4.Length=0) then continue;
                var s_len_4 := s_org_el_4.Length;
                var s_tmp_el_4_ptr := Marshal.AllocHGlobal(s_len_4 * s_el_sz);
                s_tmp_el_3[s_ind_3] := s_tmp_el_4_ptr;
                for var s_ind_4 := 0 to s_len_4-1 do
                begin
                  var s_tmp_el_4_ptr_typed: ^IntPtr := s_tmp_el_4_ptr.ToPointer;
                  s_tmp_el_4_ptr_typed^ := s_org_el_4[s_ind_4];
                  s_tmp_el_4_ptr := s_tmp_el_4_ptr + s_el_sz;
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfString(s_temp_arr);
      finally
         foreach var arr_el1 in s_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do Marshal.FreeHGlobal(arr_el3);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfString(s: array of array of array of IntPtr);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of array of IntPtr;
      try
        begin
          var s_el_sz := Marshal.SizeOf&<IntPtr>;
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            SetLength(s_tmp_el_1[s_ind_1], s_len_2);
            var s_tmp_el_2 := s_tmp_el_1[s_ind_1];
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_org_el_3 := s_org_el_2[s_ind_2];
              if (s_org_el_3=nil) or (s_org_el_3.Length=0) then continue;
              var s_len_3 := s_org_el_3.Length;
              var s_tmp_el_3_ptr := Marshal.AllocHGlobal(s_len_3 * s_el_sz);
              s_tmp_el_2[s_ind_2] := s_tmp_el_3_ptr;
              for var s_ind_3 := 0 to s_len_3-1 do
              begin
                var s_tmp_el_3_ptr_typed: ^IntPtr := s_tmp_el_3_ptr.ToPointer;
                s_tmp_el_3_ptr_typed^ := s_org_el_3[s_ind_3];
                s_tmp_el_3_ptr := s_tmp_el_3_ptr + s_el_sz;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfString(s_temp_arr);
      finally
         foreach var arr_el1 in s_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do Marshal.FreeHGlobal(arr_el2);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfString(s: array of array of IntPtr);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of IntPtr;
      try
        begin
          var s_el_sz := Marshal.SizeOf&<IntPtr>;
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            var s_tmp_el_2_ptr := Marshal.AllocHGlobal(s_len_2 * s_el_sz);
            s_tmp_el_1[s_ind_1] := s_tmp_el_2_ptr;
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_tmp_el_2_ptr_typed: ^IntPtr := s_tmp_el_2_ptr.ToPointer;
              s_tmp_el_2_ptr_typed^ := s_org_el_2[s_ind_2];
              s_tmp_el_2_ptr := s_tmp_el_2_ptr + s_el_sz;
            end;
          end;
        end;
        ntv_f5ArrrrrrayOfString_2(s_temp_arr[0]);
      finally
         foreach var arr_el1 in s_temp_arr do Marshal.FreeHGlobal(arr_el1);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfString(var s: IntPtr) :=
      ntv_f5ArrrrrrayOfString_2(s);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f5ArrrrrrayOfString(s: pointer) :=
      ntv_f5ArrrrrrayOfString_1(s);
    
    // added in dum1.0
    private static function ntv_f6Mix_1(s1: IntPtr; s2: IntPtr; var gen: Byte; var gen_ro: Byte): IntPtr;
      external 'dummy.dll' name 'f6Mix';
    private static function ntv_f6Mix_2(s1: IntPtr; s2: IntPtr; var gen: Byte; gen_ro: pointer): IntPtr;
      external 'dummy.dll' name 'f6Mix';
    private static function ntv_f6Mix_3(s1: IntPtr; s2: IntPtr; gen: pointer; var gen_ro: Byte): IntPtr;
      external 'dummy.dll' name 'f6Mix';
    private static function ntv_f6Mix_4(s1: IntPtr; s2: IntPtr; gen: pointer; gen_ro: pointer): IntPtr;
      external 'dummy.dll' name 'f6Mix';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T,T2>(s1: IntPtr; s2: string; gen: array of T; gen_ro: array of T2): string; where T, T2: record;
      type PT = ^T;
      type PT2 = ^T2;
    begin
      Result := if (gen_ro<>nil) and (gen_ro.Length<>0) then
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], gen_ro[0]) else
          f6Mix(s1, s2, PT(nil)^, gen_ro[0]) else
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], PT2(nil)^) else
          f6Mix(s1, s2, PT(nil)^, PT2(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T,T2>(s1: IntPtr; s2: IntPtr; gen: array of T; gen_ro: array of T2): string; where T, T2: record;
      type PT = ^T;
      type PT2 = ^T2;
    begin
      Result := if (gen_ro<>nil) and (gen_ro.Length<>0) then
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], gen_ro[0]) else
          f6Mix(s1, s2, PT(nil)^, gen_ro[0]) else
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], PT2(nil)^) else
          f6Mix(s1, s2, PT(nil)^, PT2(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T,T2>(s1: IntPtr; s2: string; var gen: T; var gen_ro: T2): string; where T, T2: record;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T>(s1: IntPtr; s2: string; var gen: T; gen_ro: pointer): string; where T: record;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T2>(s1: IntPtr; s2: string; gen: pointer; var gen_ro: T2): string; where T2: record;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix(s1: IntPtr; s2: string; gen: pointer; gen_ro: pointer): string;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T,T2>(s1: IntPtr; s2: IntPtr; var gen: T; var gen_ro: T2): string; where T, T2: record;
    begin
      var Result_str_ptr := ntv_f6Mix_1(s1, s2, PByte(pointer(@gen))^, PByte(pointer(@gen_ro))^);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T>(s1: IntPtr; s2: IntPtr; var gen: T; gen_ro: pointer): string; where T: record;
    begin
      var Result_str_ptr := ntv_f6Mix_2(s1, s2, PByte(pointer(@gen))^, gen_ro);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix<T2>(s1: IntPtr; s2: IntPtr; gen: pointer; var gen_ro: T2): string; where T2: record;
    begin
      var Result_str_ptr := ntv_f6Mix_3(s1, s2, gen, PByte(pointer(@gen_ro))^);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static function f6Mix(s1: IntPtr; s2: IntPtr; gen: pointer; gen_ro: pointer): string;
    begin
      var Result_str_ptr := ntv_f6Mix_4(s1, s2, gen, gen_ro);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    
    // added in dum1.0
    private static procedure ntv_f7EnumToType_1(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; var otp_value: Byte; var otp_value_size_ret: UIntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_2(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; var otp_value: Byte; otp_value_size_ret: IntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_3(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_4(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_5(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: Byte; var otp_value_size_ret: UIntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_6(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: Byte; otp_value_size_ret: IntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_7(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    private static procedure ntv_f7EnumToType_8(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr);
      external 'dummy.dll' name 'f7EnumToType';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType<TInp,T>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; var otp_value: T; var otp_value_size_ret: UIntPtr); where TInp, T: record;
    begin
      ntv_f7EnumToType_1(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType<TInp,T>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; var otp_value: T; otp_value_size_ret: IntPtr); where TInp, T: record;
    begin
      ntv_f7EnumToType_2(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType<TInp>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr); where TInp: record;
    begin
      ntv_f7EnumToType_3(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, otp_value, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType<TInp>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr); where TInp: record;
    begin
      ntv_f7EnumToType_4(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, otp_value, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType<T>(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: T; var otp_value_size_ret: UIntPtr); where T: record;
    begin
      ntv_f7EnumToType_5(choise, inp_value_size, inp_value, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType<T>(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: T; otp_value_size_ret: IntPtr); where T: record;
    begin
      ntv_f7EnumToType_6(choise, inp_value_size, inp_value, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr) :=
      ntv_f7EnumToType_7(choise, inp_value_size, inp_value, otp_value_size, otp_value, otp_value_size_ret);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr) :=
      ntv_f7EnumToType_8(choise, inp_value_size, inp_value, otp_value_size, otp_value, otp_value_size_ret);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_1_InpFlat(inp_value: UIntPtr; var otp_value: string);
    begin
      var inp_value_sz := new UIntPtr(Marshal.SizeOf&<UIntPtr>);
      var otp_value_sz: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_1_InpFlat, inp_value_sz,inp_value, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        f7EnumToType(Multichoise1.Choise1_1_InpFlat, inp_value_sz,inp_value, otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_2_InpArr(inp_value: array of UIntPtr; var otp_value: string);
    begin
      var inp_value_sz := new UIntPtr(inp_value.Length*Marshal.SizeOf&<UIntPtr>);
      var otp_value_sz: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value[0], UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value[0], otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_2_InpArr(inp_value_count: UInt32; var inp_value: UIntPtr; var otp_value: string);
    begin
      var inp_value_sz := new UIntPtr(inp_value_count*Marshal.SizeOf&<UIntPtr>);
      var otp_value_sz: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value, otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_3_OtpFlat(var otp_value: UIntPtr; otp_value_validate_size: boolean := false);
    begin
      var otp_value_sz := new UIntPtr(Marshal.SizeOf&<UIntPtr>);
      var otp_value_ret_size: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_3_OtpFlat, UIntPtr.Zero,nil, otp_value_sz,otp_value,otp_value_ret_size);
      if otp_value_validate_size and (otp_value_ret_size<>otp_value_sz) then
        raise new InvalidOperationException($'Implementation returned a size of {otp_value_ret_size} instead of {otp_value_sz}');
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_4_OtpArr(var otp_value: array of UIntPtr);
    begin
      var otp_value_sz: UIntPtr;
      ntv_f7EnumToType_7(Multichoise1.Choise1_4_OtpArr, UIntPtr.Zero,nil, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := new UIntPtr[otp_value_sz.ToUInt64 div Marshal.SizeOf&<UIntPtr>];
      f7EnumToType(Multichoise1.Choise1_4_OtpArr, UIntPtr.Zero,nil, otp_value_sz,otp_value_temp_res[0],IntPtr.Zero);
      otp_value := otp_value_temp_res;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_4_OtpArr(otp_value_count: UInt32; var otp_value: UIntPtr);
    begin
      var otp_value_sz := new UIntPtr(otp_value_count*Marshal.SizeOf&<UIntPtr>);
      f7EnumToType(Multichoise1.Choise1_4_OtpArr, UIntPtr.Zero,nil, otp_value_sz,otp_value,IntPtr.Zero);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_5_OtpStaticArr(var otp_value: array of UIntPtr; otp_value_validate_size: boolean := false);
    begin
      var otp_value_sz := new UIntPtr(3*Marshal.SizeOf&<UIntPtr>);
      var otp_value_temp_res := new UIntPtr[3];
      var otp_value_ret_size: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_5_OtpStaticArr, UIntPtr.Zero,nil, otp_value_sz,otp_value_temp_res[0],otp_value_ret_size);
      otp_value := otp_value_temp_res;
      if otp_value_validate_size and (otp_value_ret_size<>otp_value_sz) then
        raise new InvalidOperationException($'Implementation returned a size of {otp_value_ret_size} instead of {otp_value_sz}');
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_5_OtpStaticArr(otp_value_count: UInt32; var otp_value: UIntPtr; otp_value_validate_size: boolean := false);
    begin
      var otp_value_sz := new UIntPtr(otp_value_count*Marshal.SizeOf&<UIntPtr>);
      var otp_value_ret_size: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_5_OtpStaticArr, UIntPtr.Zero,nil, otp_value_sz,otp_value,otp_value_ret_size);
      if otp_value_validate_size and (otp_value_ret_size<>otp_value_sz) then
        raise new InvalidOperationException($'Implementation returned a size of {otp_value_ret_size} instead of {otp_value_sz}');
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToType_Choise1_6_OtpString(var otp_value: string);
    begin
      var otp_value_sz: UIntPtr;
      ntv_f7EnumToType_7(Multichoise1.Choise1_6_OtpString, UIntPtr.Zero,nil, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        ntv_f7EnumToType_8(Multichoise1.Choise1_6_OtpString, UIntPtr.Zero,nil, otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    
    // added in dum1.0
    private static procedure ntv_f7EnumToTypeInputOnly_1(choise: Multichoise2; inp_value_size: UIntPtr; var inp_value: Byte);
      external 'dummy.dll' name 'f7EnumToTypeInputOnly';
    private static procedure ntv_f7EnumToTypeInputOnly_2(choise: Multichoise2; inp_value_size: UIntPtr; inp_value: pointer);
      external 'dummy.dll' name 'f7EnumToTypeInputOnly';
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToTypeInputOnly<TInp>(choise: Multichoise2; inp_value_size: UIntPtr; var inp_value: TInp); where TInp: record;
    begin
      ntv_f7EnumToTypeInputOnly_1(choise, inp_value_size, PByte(pointer(@inp_value))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToTypeInputOnly_Choise2_1_InpFlat(inp_value: UIntPtr);
    begin
      var inp_value_sz := new UIntPtr(Marshal.SizeOf&<UIntPtr>);
      f7EnumToTypeInputOnly(Multichoise2.Choise2_1_InpFlat, inp_value_sz,inp_value);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToTypeInputOnly_Choise2_2_InpArr(inp_value: array of UIntPtr);
    begin
      var inp_value_sz := new UIntPtr(inp_value.Length*Marshal.SizeOf&<UIntPtr>);
      f7EnumToTypeInputOnly(Multichoise2.Choise2_2_InpArr, inp_value_sz,inp_value[0]);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToTypeInputOnly_Choise2_2_InpArr(inp_value_count: UInt32; var inp_value: UIntPtr);
    begin
      var inp_value_sz := new UIntPtr(inp_value_count*Marshal.SizeOf&<UIntPtr>);
      f7EnumToTypeInputOnly(Multichoise2.Choise2_2_InpArr, inp_value_sz,inp_value);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] static procedure f7EnumToTypeInputOnly(choise: Multichoise2; inp_value_size: UIntPtr; inp_value: pointer) :=
      ntv_f7EnumToTypeInputOnly_2(choise, inp_value_size, inp_value);
    
  end;
  
  {$ifndef DEBUG}
  [System.Security.SuppressUnmanagedCodeSecurity]
  {$endif DEBUG}
  [PCUNotRestore]
  ///
  dyn = sealed partial class
    public constructor(loader: DummyLoader);
    private constructor := raise new NotSupportedException;
    private function GetProcAddress(name: string): IntPtr;
    private static function GetProcOrNil<T>(fadr: IntPtr) :=
      if fadr=IntPtr.Zero then default(T) else
        Marshal.GetDelegateForFunctionPointer&<T>(fadr);
    
    // added in dyn1.0
    public f1NoParam_adr := GetProcAddress('f1NoParam');
    private ntv_f1NoParam_1 := GetProcOrNil&<procedure>(f1NoParam_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f1NoParam :=
      ntv_f1NoParam_1;
    
    // added in dyn1.0
    public f1NoParamResult_adr := GetProcAddress('f1NoParamResult');
    private ntv_f1NoParamResult_1 := GetProcOrNil&<function: UIntPtr>(f1NoParamResult_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f1NoParamResult: UIntPtr :=
      ntv_f1NoParamResult_1;
    
    // added in dyn1.0
    public f2ParamString_adr := GetProcAddress('f2ParamString');
    private ntv_f2ParamString_1 := GetProcOrNil&<procedure(s: IntPtr)>(f2ParamString_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f2ParamString(s: IntPtr) :=
      ntv_f2ParamString_1(s);
    
    // added in dyn1.0
    public f2ParamStringRO_adr := GetProcAddress('f2ParamStringRO');
    private ntv_f2ParamStringRO_1 := GetProcOrNil&<procedure(s: IntPtr)>(f2ParamStringRO_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f2ParamStringRO(s: string);
    begin
      var s_str_ptr := Marshal.StringToHGlobalAnsi(s);
      try
        ntv_f2ParamStringRO_1(s_str_ptr);
      finally
        Marshal.FreeHGlobal(s_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f2ParamStringRO(s: IntPtr) :=
      ntv_f2ParamStringRO_1(s);
    
    // added in dyn1.0
    public f3ResultString_adr := GetProcAddress('f3ResultString');
    private ntv_f3ResultString_1 := GetProcOrNil&<function: IntPtr>(f3ResultString_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f3ResultString: string;
    begin
      var Result_str_ptr := ntv_f3ResultString_1;
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    
    // added in dyn1.0
    public f3ResultStringRO_adr := GetProcAddress('f3ResultStringRO');
    private ntv_f3ResultStringRO_1 := GetProcOrNil&<function: IntPtr>(f3ResultStringRO_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f3ResultStringRO: string :=
      Marshal.PtrToStringAnsi(ntv_f3ResultStringRO_1);
    
    // added in dyn1.0
    public f4Generic_adr := GetProcAddress('f4Generic');
    private ntv_f4Generic_1 := GetProcOrNil&<procedure(var data: Byte)>(f4Generic_adr);
    private ntv_f4Generic_2 := GetProcOrNil&<procedure(data: pointer)>(f4Generic_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4Generic<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        f4Generic(data[0]) else
        f4Generic(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4Generic<T>(var data: T); where T: record;
    begin
      ntv_f4Generic_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4Generic(data: pointer) :=
      ntv_f4Generic_2(data);
    
    // added in dyn1.0
    public f4GenericRO_adr := GetProcAddress('f4GenericRO');
    private ntv_f4GenericRO_1 := GetProcOrNil&<procedure(var data: Byte)>(f4GenericRO_adr);
    private ntv_f4GenericRO_2 := GetProcOrNil&<procedure(data: pointer)>(f4GenericRO_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericRO<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        f4GenericRO(data[0]) else
        f4GenericRO(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericRO<T>(var data: T); where T: record;
    begin
      ntv_f4GenericRO_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericRO(data: pointer) :=
      ntv_f4GenericRO_2(data);
    
    // added in dyn1.0
    public f4GenericWOVarArg_adr := GetProcAddress('f4GenericWOVarArg');
    private ntv_f4GenericWOVarArg_1 := GetProcOrNil&<procedure(var data: Byte)>(f4GenericWOVarArg_adr);
    private ntv_f4GenericWOVarArg_2 := GetProcOrNil&<procedure(data: pointer)>(f4GenericWOVarArg_adr);
    private [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure temp_f4GenericWOVarArg_1<T>(var data: T); where T: record;
    begin
      ntv_f4GenericWOVarArg_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericWOVarArg<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        temp_f4GenericWOVarArg_1(data[0]) else
        temp_f4GenericWOVarArg_1(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericWOVarArg(data: pointer) :=
      ntv_f4GenericWOVarArg_2(data);
    
    // added in dyn1.0
    public f4GenericWOVarArgRO_adr := GetProcAddress('f4GenericWOVarArgRO');
    private ntv_f4GenericWOVarArgRO_1 := GetProcOrNil&<procedure(var data: Byte)>(f4GenericWOVarArgRO_adr);
    private ntv_f4GenericWOVarArgRO_2 := GetProcOrNil&<procedure(data: pointer)>(f4GenericWOVarArgRO_adr);
    private [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure temp_f4GenericWOVarArgRO_1<T>(var data: T); where T: record;
    begin
      ntv_f4GenericWOVarArgRO_1(PByte(pointer(@data))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericWOVarArgRO<T>(data: array of T); where T: record;
      type PT = ^T;
    begin
      if (data<>nil) and (data.Length<>0) then
        temp_f4GenericWOVarArgRO_1(data[0]) else
        temp_f4GenericWOVarArgRO_1(PT(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f4GenericWOVarArgRO(data: pointer) :=
      ntv_f4GenericWOVarArgRO_2(data);
    
    // added in dyn1.0
    public f5Arrrrrray_adr := GetProcAddress('f5Arrrrrray');
    private ntv_f5Arrrrrray_1 := GetProcOrNil&<procedure(a: pointer)>(f5Arrrrrray_adr);
    private ntv_f5Arrrrrray_2 := GetProcOrNil&<procedure(var a: IntPtr)>(f5Arrrrrray_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5Arrrrrray(a: array of array of array of array of array of UIntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<UIntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                SetLength(a_tmp_el_3[a_ind_3], a_len_4);
                var a_tmp_el_4 := a_tmp_el_3[a_ind_3];
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_org_el_5 := a_org_el_4[a_ind_4];
                  if (a_org_el_5=nil) or (a_org_el_5.Length=0) then continue;
                  var a_len_5 := a_org_el_5.Length;
                  var a_tmp_el_5_ptr := Marshal.AllocHGlobal(a_len_5 * a_el_sz);
                  a_tmp_el_4[a_ind_4] := a_tmp_el_5_ptr;
                  for var a_ind_5 := 0 to a_len_5-1 do
                  begin
                    var a_tmp_el_5_ptr_typed: ^UIntPtr := a_tmp_el_5_ptr.ToPointer;
                    a_tmp_el_5_ptr_typed^ := a_org_el_5[a_ind_5];
                    a_tmp_el_5_ptr := a_tmp_el_5_ptr + a_el_sz;
                  end;
                end;
              end;
            end;
          end;
        end;
        f5Arrrrrray(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do if arr_el3<>nil then
               foreach var arr_el4 in arr_el3 do Marshal.FreeHGlobal(arr_el4);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5Arrrrrray(a: array of array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                var a_tmp_el_4_ptr := Marshal.AllocHGlobal(a_len_4 * a_el_sz);
                a_tmp_el_3[a_ind_3] := a_tmp_el_4_ptr;
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_tmp_el_4_ptr_typed: ^IntPtr := a_tmp_el_4_ptr.ToPointer;
                  a_tmp_el_4_ptr_typed^ := a_org_el_4[a_ind_4];
                  a_tmp_el_4_ptr := a_tmp_el_4_ptr + a_el_sz;
                end;
              end;
            end;
          end;
        end;
        f5Arrrrrray(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do Marshal.FreeHGlobal(arr_el3);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5Arrrrrray(a: array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              var a_tmp_el_3_ptr := Marshal.AllocHGlobal(a_len_3 * a_el_sz);
              a_tmp_el_2[a_ind_2] := a_tmp_el_3_ptr;
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_tmp_el_3_ptr_typed: ^IntPtr := a_tmp_el_3_ptr.ToPointer;
                a_tmp_el_3_ptr_typed^ := a_org_el_3[a_ind_3];
                a_tmp_el_3_ptr := a_tmp_el_3_ptr + a_el_sz;
              end;
            end;
          end;
        end;
        f5Arrrrrray(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do Marshal.FreeHGlobal(arr_el2);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5Arrrrrray(a: array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5Arrrrrray_1(nil);
        exit;
      end;
      var a_temp_arr: array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            var a_tmp_el_2_ptr := Marshal.AllocHGlobal(a_len_2 * a_el_sz);
            a_tmp_el_1[a_ind_1] := a_tmp_el_2_ptr;
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_tmp_el_2_ptr_typed: ^IntPtr := a_tmp_el_2_ptr.ToPointer;
              a_tmp_el_2_ptr_typed^ := a_org_el_2[a_ind_2];
              a_tmp_el_2_ptr := a_tmp_el_2_ptr + a_el_sz;
            end;
          end;
        end;
        ntv_f5Arrrrrray_2(a_temp_arr[0]);
      finally
         foreach var arr_el1 in a_temp_arr do Marshal.FreeHGlobal(arr_el1);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5Arrrrrray(var a: IntPtr) :=
      ntv_f5Arrrrrray_2(a);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5Arrrrrray(a: pointer) :=
      ntv_f5Arrrrrray_1(a);
    
    // added in dyn1.0
    public f5ArrrrrrayOfGeneric_adr := GetProcAddress('f5ArrrrrrayOfGeneric');
    private ntv_f5ArrrrrrayOfGeneric_1 := GetProcOrNil&<procedure(a: pointer)>(f5ArrrrrrayOfGeneric_adr);
    private ntv_f5ArrrrrrayOfGeneric_2 := GetProcOrNil&<procedure(var a: IntPtr)>(f5ArrrrrrayOfGeneric_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfGeneric<T>(a: array of array of array of array of array of T); where T: record;
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<T>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                SetLength(a_tmp_el_3[a_ind_3], a_len_4);
                var a_tmp_el_4 := a_tmp_el_3[a_ind_3];
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_org_el_5 := a_org_el_4[a_ind_4];
                  if (a_org_el_5=nil) or (a_org_el_5.Length=0) then continue;
                  var a_len_5 := a_org_el_5.Length;
                  var a_tmp_el_5_ptr := Marshal.AllocHGlobal(a_len_5 * a_el_sz);
                  a_tmp_el_4[a_ind_4] := a_tmp_el_5_ptr;
                  for var a_ind_5 := 0 to a_len_5-1 do
                  begin
                    var a_tmp_el_5_ptr_typed: ^T := a_tmp_el_5_ptr.ToPointer;
                    a_tmp_el_5_ptr_typed^ := a_org_el_5[a_ind_5];
                    a_tmp_el_5_ptr := a_tmp_el_5_ptr + a_el_sz;
                  end;
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfGeneric(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do if arr_el3<>nil then
               foreach var arr_el4 in arr_el3 do Marshal.FreeHGlobal(arr_el4);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfGeneric(a: array of array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              SetLength(a_tmp_el_2[a_ind_2], a_len_3);
              var a_tmp_el_3 := a_tmp_el_2[a_ind_2];
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_org_el_4 := a_org_el_3[a_ind_3];
                if (a_org_el_4=nil) or (a_org_el_4.Length=0) then continue;
                var a_len_4 := a_org_el_4.Length;
                var a_tmp_el_4_ptr := Marshal.AllocHGlobal(a_len_4 * a_el_sz);
                a_tmp_el_3[a_ind_3] := a_tmp_el_4_ptr;
                for var a_ind_4 := 0 to a_len_4-1 do
                begin
                  var a_tmp_el_4_ptr_typed: ^IntPtr := a_tmp_el_4_ptr.ToPointer;
                  a_tmp_el_4_ptr_typed^ := a_org_el_4[a_ind_4];
                  a_tmp_el_4_ptr := a_tmp_el_4_ptr + a_el_sz;
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfGeneric(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do Marshal.FreeHGlobal(arr_el3);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfGeneric(a: array of array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            SetLength(a_tmp_el_1[a_ind_1], a_len_2);
            var a_tmp_el_2 := a_tmp_el_1[a_ind_1];
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_org_el_3 := a_org_el_2[a_ind_2];
              if (a_org_el_3=nil) or (a_org_el_3.Length=0) then continue;
              var a_len_3 := a_org_el_3.Length;
              var a_tmp_el_3_ptr := Marshal.AllocHGlobal(a_len_3 * a_el_sz);
              a_tmp_el_2[a_ind_2] := a_tmp_el_3_ptr;
              for var a_ind_3 := 0 to a_len_3-1 do
              begin
                var a_tmp_el_3_ptr_typed: ^IntPtr := a_tmp_el_3_ptr.ToPointer;
                a_tmp_el_3_ptr_typed^ := a_org_el_3[a_ind_3];
                a_tmp_el_3_ptr := a_tmp_el_3_ptr + a_el_sz;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfGeneric(a_temp_arr);
      finally
         foreach var arr_el1 in a_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do Marshal.FreeHGlobal(arr_el2);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfGeneric(a: array of array of IntPtr);
    begin
      if (a=nil) or (a.Length=0) then
      begin
        ntv_f5ArrrrrrayOfGeneric_1(nil);
        exit;
      end;
      var a_temp_arr: array of IntPtr;
      try
        begin
          var a_el_sz := Marshal.SizeOf&<IntPtr>;
          var a_org_el_1 := a;
          var a_len_1 := a_org_el_1.Length;
          SetLength(a_temp_arr, a_len_1);
          var a_tmp_el_1 := a_temp_arr;
          for var a_ind_1 := 0 to a_len_1-1 do
          begin
            var a_org_el_2 := a_org_el_1[a_ind_1];
            if (a_org_el_2=nil) or (a_org_el_2.Length=0) then continue;
            var a_len_2 := a_org_el_2.Length;
            var a_tmp_el_2_ptr := Marshal.AllocHGlobal(a_len_2 * a_el_sz);
            a_tmp_el_1[a_ind_1] := a_tmp_el_2_ptr;
            for var a_ind_2 := 0 to a_len_2-1 do
            begin
              var a_tmp_el_2_ptr_typed: ^IntPtr := a_tmp_el_2_ptr.ToPointer;
              a_tmp_el_2_ptr_typed^ := a_org_el_2[a_ind_2];
              a_tmp_el_2_ptr := a_tmp_el_2_ptr + a_el_sz;
            end;
          end;
        end;
        ntv_f5ArrrrrrayOfGeneric_2(a_temp_arr[0]);
      finally
         foreach var arr_el1 in a_temp_arr do Marshal.FreeHGlobal(arr_el1);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfGeneric(var a: IntPtr) :=
      ntv_f5ArrrrrrayOfGeneric_2(a);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfGeneric(a: pointer) :=
      ntv_f5ArrrrrrayOfGeneric_1(a);
    
    // added in dyn1.0
    public f5ArrrrrrayOfString_adr := GetProcAddress('f5ArrrrrrayOfString');
    private ntv_f5ArrrrrrayOfString_1 := GetProcOrNil&<procedure(s: pointer)>(f5ArrrrrrayOfString_adr);
    private ntv_f5ArrrrrrayOfString_2 := GetProcOrNil&<procedure(var s: IntPtr)>(f5ArrrrrrayOfString_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfString(s: array of array of array of array of string);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of array of array of array of IntPtr;
      try
        begin
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            SetLength(s_tmp_el_1[s_ind_1], s_len_2);
            var s_tmp_el_2 := s_tmp_el_1[s_ind_1];
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_org_el_3 := s_org_el_2[s_ind_2];
              if (s_org_el_3=nil) or (s_org_el_3.Length=0) then continue;
              var s_len_3 := s_org_el_3.Length;
              SetLength(s_tmp_el_2[s_ind_2], s_len_3);
              var s_tmp_el_3 := s_tmp_el_2[s_ind_2];
              for var s_ind_3 := 0 to s_len_3-1 do
              begin
                var s_org_el_4 := s_org_el_3[s_ind_3];
                if (s_org_el_4=nil) or (s_org_el_4.Length=0) then continue;
                var s_len_4 := s_org_el_4.Length;
                SetLength(s_tmp_el_3[s_ind_3], s_len_4);
                var s_tmp_el_4 := s_tmp_el_3[s_ind_3];
                for var s_ind_4 := 0 to s_len_4-1 do
                begin
                  var s_org_el_5 := s_org_el_4[s_ind_4];
                  if (s_org_el_5=nil) or (s_org_el_5.Length=0) then continue;
                  s_tmp_el_4[s_ind_4] := Marshal.StringToHGlobalAnsi(s_org_el_5);
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfString(s_temp_arr);
      finally
         foreach var arr_el1 in s_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do if arr_el3<>nil then
               foreach var arr_el4 in arr_el3 do Marshal.FreeHGlobal(arr_el4);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfString(s: array of array of array of array of IntPtr);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of array of array of IntPtr;
      try
        begin
          var s_el_sz := Marshal.SizeOf&<IntPtr>;
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            SetLength(s_tmp_el_1[s_ind_1], s_len_2);
            var s_tmp_el_2 := s_tmp_el_1[s_ind_1];
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_org_el_3 := s_org_el_2[s_ind_2];
              if (s_org_el_3=nil) or (s_org_el_3.Length=0) then continue;
              var s_len_3 := s_org_el_3.Length;
              SetLength(s_tmp_el_2[s_ind_2], s_len_3);
              var s_tmp_el_3 := s_tmp_el_2[s_ind_2];
              for var s_ind_3 := 0 to s_len_3-1 do
              begin
                var s_org_el_4 := s_org_el_3[s_ind_3];
                if (s_org_el_4=nil) or (s_org_el_4.Length=0) then continue;
                var s_len_4 := s_org_el_4.Length;
                var s_tmp_el_4_ptr := Marshal.AllocHGlobal(s_len_4 * s_el_sz);
                s_tmp_el_3[s_ind_3] := s_tmp_el_4_ptr;
                for var s_ind_4 := 0 to s_len_4-1 do
                begin
                  var s_tmp_el_4_ptr_typed: ^IntPtr := s_tmp_el_4_ptr.ToPointer;
                  s_tmp_el_4_ptr_typed^ := s_org_el_4[s_ind_4];
                  s_tmp_el_4_ptr := s_tmp_el_4_ptr + s_el_sz;
                end;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfString(s_temp_arr);
      finally
         foreach var arr_el1 in s_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do if arr_el2<>nil then
             foreach var arr_el3 in arr_el2 do Marshal.FreeHGlobal(arr_el3);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfString(s: array of array of array of IntPtr);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of array of IntPtr;
      try
        begin
          var s_el_sz := Marshal.SizeOf&<IntPtr>;
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            SetLength(s_tmp_el_1[s_ind_1], s_len_2);
            var s_tmp_el_2 := s_tmp_el_1[s_ind_1];
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_org_el_3 := s_org_el_2[s_ind_2];
              if (s_org_el_3=nil) or (s_org_el_3.Length=0) then continue;
              var s_len_3 := s_org_el_3.Length;
              var s_tmp_el_3_ptr := Marshal.AllocHGlobal(s_len_3 * s_el_sz);
              s_tmp_el_2[s_ind_2] := s_tmp_el_3_ptr;
              for var s_ind_3 := 0 to s_len_3-1 do
              begin
                var s_tmp_el_3_ptr_typed: ^IntPtr := s_tmp_el_3_ptr.ToPointer;
                s_tmp_el_3_ptr_typed^ := s_org_el_3[s_ind_3];
                s_tmp_el_3_ptr := s_tmp_el_3_ptr + s_el_sz;
              end;
            end;
          end;
        end;
        f5ArrrrrrayOfString(s_temp_arr);
      finally
         foreach var arr_el1 in s_temp_arr do if arr_el1<>nil then
           foreach var arr_el2 in arr_el1 do Marshal.FreeHGlobal(arr_el2);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfString(s: array of array of IntPtr);
    begin
      if (s=nil) or (s.Length=0) then
      begin
        ntv_f5ArrrrrrayOfString_1(nil);
        exit;
      end;
      var s_temp_arr: array of IntPtr;
      try
        begin
          var s_el_sz := Marshal.SizeOf&<IntPtr>;
          var s_org_el_1 := s;
          var s_len_1 := s_org_el_1.Length;
          SetLength(s_temp_arr, s_len_1);
          var s_tmp_el_1 := s_temp_arr;
          for var s_ind_1 := 0 to s_len_1-1 do
          begin
            var s_org_el_2 := s_org_el_1[s_ind_1];
            if (s_org_el_2=nil) or (s_org_el_2.Length=0) then continue;
            var s_len_2 := s_org_el_2.Length;
            var s_tmp_el_2_ptr := Marshal.AllocHGlobal(s_len_2 * s_el_sz);
            s_tmp_el_1[s_ind_1] := s_tmp_el_2_ptr;
            for var s_ind_2 := 0 to s_len_2-1 do
            begin
              var s_tmp_el_2_ptr_typed: ^IntPtr := s_tmp_el_2_ptr.ToPointer;
              s_tmp_el_2_ptr_typed^ := s_org_el_2[s_ind_2];
              s_tmp_el_2_ptr := s_tmp_el_2_ptr + s_el_sz;
            end;
          end;
        end;
        ntv_f5ArrrrrrayOfString_2(s_temp_arr[0]);
      finally
         foreach var arr_el1 in s_temp_arr do Marshal.FreeHGlobal(arr_el1);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfString(var s: IntPtr) :=
      ntv_f5ArrrrrrayOfString_2(s);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f5ArrrrrrayOfString(s: pointer) :=
      ntv_f5ArrrrrrayOfString_1(s);
    
    // added in dyn1.0
    public f6Mix_adr := GetProcAddress('f6Mix');
    private ntv_f6Mix_1 := GetProcOrNil&<function(s1: IntPtr; s2: IntPtr; var gen: Byte; var gen_ro: Byte): IntPtr>(f6Mix_adr);
    private ntv_f6Mix_2 := GetProcOrNil&<function(s1: IntPtr; s2: IntPtr; var gen: Byte; gen_ro: pointer): IntPtr>(f6Mix_adr);
    private ntv_f6Mix_3 := GetProcOrNil&<function(s1: IntPtr; s2: IntPtr; gen: pointer; var gen_ro: Byte): IntPtr>(f6Mix_adr);
    private ntv_f6Mix_4 := GetProcOrNil&<function(s1: IntPtr; s2: IntPtr; gen: pointer; gen_ro: pointer): IntPtr>(f6Mix_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T,T2>(s1: IntPtr; s2: string; gen: array of T; gen_ro: array of T2): string; where T, T2: record;
      type PT = ^T;
      type PT2 = ^T2;
    begin
      Result := if (gen_ro<>nil) and (gen_ro.Length<>0) then
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], gen_ro[0]) else
          f6Mix(s1, s2, PT(nil)^, gen_ro[0]) else
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], PT2(nil)^) else
          f6Mix(s1, s2, PT(nil)^, PT2(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T,T2>(s1: IntPtr; s2: IntPtr; gen: array of T; gen_ro: array of T2): string; where T, T2: record;
      type PT = ^T;
      type PT2 = ^T2;
    begin
      Result := if (gen_ro<>nil) and (gen_ro.Length<>0) then
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], gen_ro[0]) else
          f6Mix(s1, s2, PT(nil)^, gen_ro[0]) else
        if (gen<>nil) and (gen.Length<>0) then
          f6Mix(s1, s2, gen[0], PT2(nil)^) else
          f6Mix(s1, s2, PT(nil)^, PT2(nil)^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T,T2>(s1: IntPtr; s2: string; var gen: T; var gen_ro: T2): string; where T, T2: record;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T>(s1: IntPtr; s2: string; var gen: T; gen_ro: pointer): string; where T: record;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T2>(s1: IntPtr; s2: string; gen: pointer; var gen_ro: T2): string; where T2: record;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix(s1: IntPtr; s2: string; gen: pointer; gen_ro: pointer): string;
    begin
      var s2_str_ptr := Marshal.StringToHGlobalAnsi(s2);
      try
        Result := f6Mix(s1, s2_str_ptr, gen, gen_ro);
      finally
        Marshal.FreeHGlobal(s2_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T,T2>(s1: IntPtr; s2: IntPtr; var gen: T; var gen_ro: T2): string; where T, T2: record;
    begin
      var Result_str_ptr := ntv_f6Mix_1(s1, s2, PByte(pointer(@gen))^, PByte(pointer(@gen_ro))^);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T>(s1: IntPtr; s2: IntPtr; var gen: T; gen_ro: pointer): string; where T: record;
    begin
      var Result_str_ptr := ntv_f6Mix_2(s1, s2, PByte(pointer(@gen))^, gen_ro);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix<T2>(s1: IntPtr; s2: IntPtr; gen: pointer; var gen_ro: T2): string; where T2: record;
    begin
      var Result_str_ptr := ntv_f6Mix_3(s1, s2, gen, PByte(pointer(@gen_ro))^);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function f6Mix(s1: IntPtr; s2: IntPtr; gen: pointer; gen_ro: pointer): string;
    begin
      var Result_str_ptr := ntv_f6Mix_4(s1, s2, gen, gen_ro);
      try
        Result := Marshal.PtrToStringAnsi(Result_str_ptr);
      finally
        Marshal.FreeHGlobal(Result_str_ptr);
      end;
    end;
    
    // added in dyn1.0
    public f7EnumToType_adr := GetProcAddress('f7EnumToType');
    private ntv_f7EnumToType_1 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; var otp_value: Byte; var otp_value_size_ret: UIntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_2 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; var otp_value: Byte; otp_value_size_ret: IntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_3 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_4 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: Byte; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_5 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: Byte; var otp_value_size_ret: UIntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_6 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: Byte; otp_value_size_ret: IntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_7 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr)>(f7EnumToType_adr);
    private ntv_f7EnumToType_8 := GetProcOrNil&<procedure(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr)>(f7EnumToType_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType<TInp,T>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; var otp_value: T; var otp_value_size_ret: UIntPtr); where TInp, T: record;
    begin
      ntv_f7EnumToType_1(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType<TInp,T>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; var otp_value: T; otp_value_size_ret: IntPtr); where TInp, T: record;
    begin
      ntv_f7EnumToType_2(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType<TInp>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr); where TInp: record;
    begin
      ntv_f7EnumToType_3(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, otp_value, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType<TInp>(choise: Multichoise1; inp_value_size: UIntPtr; var inp_value: TInp; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr); where TInp: record;
    begin
      ntv_f7EnumToType_4(choise, inp_value_size, PByte(pointer(@inp_value))^, otp_value_size, otp_value, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType<T>(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: T; var otp_value_size_ret: UIntPtr); where T: record;
    begin
      ntv_f7EnumToType_5(choise, inp_value_size, inp_value, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType<T>(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; var otp_value: T; otp_value_size_ret: IntPtr); where T: record;
    begin
      ntv_f7EnumToType_6(choise, inp_value_size, inp_value, otp_value_size, PByte(pointer(@otp_value))^, otp_value_size_ret);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; var otp_value_size_ret: UIntPtr) :=
      ntv_f7EnumToType_7(choise, inp_value_size, inp_value, otp_value_size, otp_value, otp_value_size_ret);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType(choise: Multichoise1; inp_value_size: UIntPtr; inp_value: pointer; otp_value_size: UIntPtr; otp_value: pointer; otp_value_size_ret: IntPtr) :=
      ntv_f7EnumToType_8(choise, inp_value_size, inp_value, otp_value_size, otp_value, otp_value_size_ret);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_1_InpFlat(inp_value: UIntPtr; var otp_value: string);
    begin
      var inp_value_sz := new UIntPtr(Marshal.SizeOf&<UIntPtr>);
      var otp_value_sz: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_1_InpFlat, inp_value_sz,inp_value, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        f7EnumToType(Multichoise1.Choise1_1_InpFlat, inp_value_sz,inp_value, otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_2_InpArr(inp_value: array of UIntPtr; var otp_value: string);
    begin
      var inp_value_sz := new UIntPtr(inp_value.Length*Marshal.SizeOf&<UIntPtr>);
      var otp_value_sz: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value[0], UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value[0], otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_2_InpArr(inp_value_count: UInt32; var inp_value: UIntPtr; var otp_value: string);
    begin
      var inp_value_sz := new UIntPtr(inp_value_count*Marshal.SizeOf&<UIntPtr>);
      var otp_value_sz: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        f7EnumToType(Multichoise1.Choise1_2_InpArr, inp_value_sz,inp_value, otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_3_OtpFlat(var otp_value: UIntPtr; otp_value_validate_size: boolean := false);
    begin
      var otp_value_sz := new UIntPtr(Marshal.SizeOf&<UIntPtr>);
      var otp_value_ret_size: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_3_OtpFlat, UIntPtr.Zero,nil, otp_value_sz,otp_value,otp_value_ret_size);
      if otp_value_validate_size and (otp_value_ret_size<>otp_value_sz) then
        raise new InvalidOperationException($'Implementation returned a size of {otp_value_ret_size} instead of {otp_value_sz}');
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_4_OtpArr(var otp_value: array of UIntPtr);
    begin
      var otp_value_sz: UIntPtr;
      ntv_f7EnumToType_7(Multichoise1.Choise1_4_OtpArr, UIntPtr.Zero,nil, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := new UIntPtr[otp_value_sz.ToUInt64 div Marshal.SizeOf&<UIntPtr>];
      f7EnumToType(Multichoise1.Choise1_4_OtpArr, UIntPtr.Zero,nil, otp_value_sz,otp_value_temp_res[0],IntPtr.Zero);
      otp_value := otp_value_temp_res;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_4_OtpArr(otp_value_count: UInt32; var otp_value: UIntPtr);
    begin
      var otp_value_sz := new UIntPtr(otp_value_count*Marshal.SizeOf&<UIntPtr>);
      f7EnumToType(Multichoise1.Choise1_4_OtpArr, UIntPtr.Zero,nil, otp_value_sz,otp_value,IntPtr.Zero);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_5_OtpStaticArr(var otp_value: array of UIntPtr; otp_value_validate_size: boolean := false);
    begin
      var otp_value_sz := new UIntPtr(3*Marshal.SizeOf&<UIntPtr>);
      var otp_value_temp_res := new UIntPtr[3];
      var otp_value_ret_size: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_5_OtpStaticArr, UIntPtr.Zero,nil, otp_value_sz,otp_value_temp_res[0],otp_value_ret_size);
      otp_value := otp_value_temp_res;
      if otp_value_validate_size and (otp_value_ret_size<>otp_value_sz) then
        raise new InvalidOperationException($'Implementation returned a size of {otp_value_ret_size} instead of {otp_value_sz}');
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_5_OtpStaticArr(otp_value_count: UInt32; var otp_value: UIntPtr; otp_value_validate_size: boolean := false);
    begin
      var otp_value_sz := new UIntPtr(otp_value_count*Marshal.SizeOf&<UIntPtr>);
      var otp_value_ret_size: UIntPtr;
      f7EnumToType(Multichoise1.Choise1_5_OtpStaticArr, UIntPtr.Zero,nil, otp_value_sz,otp_value,otp_value_ret_size);
      if otp_value_validate_size and (otp_value_ret_size<>otp_value_sz) then
        raise new InvalidOperationException($'Implementation returned a size of {otp_value_ret_size} instead of {otp_value_sz}');
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToType_Choise1_6_OtpString(var otp_value: string);
    begin
      var otp_value_sz: UIntPtr;
      ntv_f7EnumToType_7(Multichoise1.Choise1_6_OtpString, UIntPtr.Zero,nil, UIntPtr.Zero,nil,otp_value_sz);
      if otp_value_sz = UIntPtr.Zero then
      begin
        otp_value := nil;
        exit;
      end;
      var otp_value_temp_res := Marshal.AllocHGlobal(IntPtr(otp_value_sz.ToPointer));
      try
        ntv_f7EnumToType_8(Multichoise1.Choise1_6_OtpString, UIntPtr.Zero,nil, otp_value_sz,otp_value_temp_res.ToPointer,IntPtr.Zero);
        otp_value := Marshal.PtrToStringAnsi(otp_value_temp_res);
      finally
        Marshal.FreeHGlobal(otp_value_temp_res);
      end;
    end;
    
    // added in dyn1.0
    public f7EnumToTypeInputOnly_adr := GetProcAddress('f7EnumToTypeInputOnly');
    private ntv_f7EnumToTypeInputOnly_1 := GetProcOrNil&<procedure(choise: Multichoise2; inp_value_size: UIntPtr; var inp_value: Byte)>(f7EnumToTypeInputOnly_adr);
    private ntv_f7EnumToTypeInputOnly_2 := GetProcOrNil&<procedure(choise: Multichoise2; inp_value_size: UIntPtr; inp_value: pointer)>(f7EnumToTypeInputOnly_adr);
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToTypeInputOnly<TInp>(choise: Multichoise2; inp_value_size: UIntPtr; var inp_value: TInp); where TInp: record;
    begin
      ntv_f7EnumToTypeInputOnly_1(choise, inp_value_size, PByte(pointer(@inp_value))^);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToTypeInputOnly_Choise2_1_InpFlat(inp_value: UIntPtr);
    begin
      var inp_value_sz := new UIntPtr(Marshal.SizeOf&<UIntPtr>);
      f7EnumToTypeInputOnly(Multichoise2.Choise2_1_InpFlat, inp_value_sz,inp_value);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToTypeInputOnly_Choise2_2_InpArr(inp_value: array of UIntPtr);
    begin
      var inp_value_sz := new UIntPtr(inp_value.Length*Marshal.SizeOf&<UIntPtr>);
      f7EnumToTypeInputOnly(Multichoise2.Choise2_2_InpArr, inp_value_sz,inp_value[0]);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToTypeInputOnly_Choise2_2_InpArr(inp_value_count: UInt32; var inp_value: UIntPtr);
    begin
      var inp_value_sz := new UIntPtr(inp_value_count*Marshal.SizeOf&<UIntPtr>);
      f7EnumToTypeInputOnly(Multichoise2.Choise2_2_InpArr, inp_value_sz,inp_value);
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] procedure f7EnumToTypeInputOnly(choise: Multichoise2; inp_value_size: UIntPtr; inp_value: pointer) :=
      ntv_f7EnumToTypeInputOnly_2(choise, inp_value_size, inp_value);
    
  end;
  
  {$endregion Подпрограммы ядра}
  
  {$region Подпрограммы расширений}
  
  
  
  {$endregion Подпрограммы расширений}
  
implementation

{$region Вспомогательные типы}



{$endregion Вспомогательные типы}

{$region Особые типы}

type
  api_with_loader = abstract class
    public loader: DummyLoader;
    
    public constructor(loader: DummyLoader) := self.loader := loader;
    private constructor := raise new NotSupportedException;
    
  end;
  
{$endregion Особые типы}

{$region Подпрограммы ядра}

type dyn = sealed partial class(api_with_loader) end;
constructor dyn.Create(loader: DummyLoader) := inherited Create(loader);
function dyn.GetProcAddress(name: string) := loader.GetProcAddress(name);

{$endregion Подпрограммы ядра}

{$region Подпрограммы расширений}



{$endregion Подпрограммы расширений}

end.