


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function(T, cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
                         █          ██████ █         █                █    █   █                    
            ██            █          █                              ██    █   █       █             
           █  █            ██                                       █                ███     ██   ██
           ████           █   █        █                       █           ██       ██  █    ██   ██
             █            ██  ██      ███                      █                      ███           
            █            ███  █       █   ██     ██            █                                    
            ██           ██  ██         █  █    █                       ██                          
           ██ █             ██          ███    █   █                                █  █            
              ██                              █     █                              █   █            
         ██    █                         ███  █  █ ██                           █████ ███           
          █ █   █                       █   █ █   █ █                          █ ██               █ 
█       █   █                           █      ███ █           ██              █                   █
      █                                 ██ █ ██                ██              ███      ██          
           █                ██           ███ ██                                        ███          
    ██     █   █            ██             █                                           █  █         
    █         █                          ██ ██                                         █  █         
   █      █ ███                          ██ █                                          █ █          
    ██    █   █       ██     ██          █  █                                                ████ █ 
    ███   █ ██       ██ █   █ ██          ██                                                 █   █  
 █      █   █       █  ███ ███  █                                                           ██   ██ 
  █      ██        ██    ███    ██                                                             █ █ █
 █                  ██    █    ██                                                             ███   
█                    █         █                          █                                      ██ 
                       █     █                             █                   █                  ██
                                   █  ███          ██    ███                  █ █                 ██
                         ███       █   ██          █ █                           █                  
                          █        █  ██            █ █                     ██   █                  
                          █           █              █                      ██████ ███              
                     ██                 █     ███                             █ ███   █    ███      
                    █  █               █                                   █      █   █    █  ██    
                     █ █                    █     █                      █   █    █   █     ███     
                      █                     █     █                     ███ ██     ███       █      
                                █           █     █                           █                     
                                █                                     ██       ██         ██        
         ███                    █             ███                     █       ██          ██        
                                                           ███        █                             
                                                                         █                          
                               ██           █                                                       
                              ██ █         █ █                                                  █   
                                            █ █                            ███                   █  
                                             ██                             ███ █   ██          █   
                              █     █ ██                     █         █  ███ ████  ██              
                               ███ ███                      █ █       ██ █ █ ██  █  ██              
                                  █      █                  █ █           █  █   █   ██             
                                   ██ ██ ██                  █                █ ██ ████  █          
     ██                               ███  █                                   █ ██   █  ███        
     ██                    █               ██                                     ██  ██   ██       
                         ██ █        ██    ██                                        █  █    ██ █ ██
                         ████      ██ ████ ██                                         █  █ █ █ █████
                               █    █ █    █                                              ██ ██████ 
    █                        ██ █    █  █  █                                      ███               
   ██                      ████  █      █                                         ███               
  ██                      █      █       █  ██                          ██     ██   █  █        ███ 
  ██                       ████████       ████                                 █      ██            
  █                         █    ██                                            █  █  █              
 █                              █                                     ██         █   █  █           
                                        █             ██       ███    ██              ███    █      
                                      ██  █          █  █     █   █           ██    █  █ ███  ██    
                                     █   ██          █  █    █   ██           █     ████  █  ██     
       █                ██       ███      █           ██         ██                 █     █         
      █ ██              █       ██       ██                 █      █         ██   █      █          
      █  █    ██         ██ █  █   █     ██                       ██         █ ███    █ █           
   █   █  █  ██           █ ████      █ ██                  ██      █       █  █  █                 
  ██  ███     █  █           ██                                ███ █            ██            ██    
 █   ██       █  █                                           ████ ██      ███   █         ██  █ █   
   █ ██       █  █             █                            █ ██           █ ██           ██   █    
     █        ██         ██    ██                          █                ███                     
 █  █                    ██                               ██                 █    ███               
  █                                       ███            █ █     █   ███                            
                                                        ███     ███  █ █                            
                                        █                █  █   ██    ██                            
                                        █                 █      █ █      ██                        
                                        █                 ███    █      ██ ██                       
       ██              █ █ ██ █   █                             █     ███ ███    ██                 
     ██  █           ██    ██ █   ███                            █         █     ██                 
     █  ███          █ █   █ ██  █  █                             ██  ██████          █             
     █    █          █           ███                                  ██  █         ██              
      █████          ██         ██                                      ██                          
        ██          █ █         █                                                  █       ██       
              ██    █  █             █                                                ██   ██       
              ██       █             █                         █                  █     █           
                    █                █                         ███              █ █    █            
                    █                                                          █ ██                 
                     █  ██                               █      ██                 █ █              
                      ███          ██                   ██     █               ██ █                 
       ██              █           ██                   █                       █                   
       ██                                               █ ██                     ██  █ ████         
                    █                                    ███   ██    ██            ██ ████          
  █               ██ ██                                      ██ █    ██              ███            
 ███              ██  █               ██                     ██ █             █      █ █            
██ ██            █    █          ██   ██                      █ █            █ █  ██           ███  
██   █            ████          █  █                       █    ██           ██   █  ██          █  
█ ██ █     █      ██             ██                        █    ██             █    ██       ██    █
 ████    █   █                                             █   █    █          █   ██        ███ ██ 
 █       █    █                                      ███    ███     █          ██  █          █  █  
         █    █                                      █      ███     █           █ █             █   
             █             █         █ █               █  █                     ███            ██  █
                          █  █ █    █                      █                    █               █ █ 
                         █ █   █    █      █         █  █ █         █          ██                   
                        ██ ██      █        █        █   █          ██        █ █                   
[EventDebug]: 102 event's created
[QueueDebug]: 1 queue's created
[ExecDebug]: 1 cache entries created
[QueueResNil]: 301
[QueueRes<T>]: 155
	QueueResValDirect<CLArray<byte>>: 51
	QueueResValDirect<array[,] of byte>: 1
	QueueResValDirect<integer>: 102
	QueueResValWrap<array[,] of byte>: 1

#ReqModules
OpenCLABC


