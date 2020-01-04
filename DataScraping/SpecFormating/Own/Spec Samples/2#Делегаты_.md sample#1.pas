static function SetEventCallback(&event: cl_event; command_exec_callback_type: CommandExecutionStatus; pfn_notify: Event_Callback; user_data: pointer): ErrorCode;
    external 'opencl.dll' name 'clSetEventCallback';
    static function SetEventCallback(&event: cl_event; command_exec_callback_type: CommandExecutionStatus; pfn_notify: IntPtr; user_data: pointer): ErrorCode;
    external 'opencl.dll' name 'clSetEventCallback';