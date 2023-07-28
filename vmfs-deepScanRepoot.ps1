<#
    AUTHER======: Garvey Snow
    VERSION=====: 1.4
    DESCRIPTION=: Iterates through datastore’s within a datacentre on vCenter and check inventoried folders against registered VM’s
		          Returns an object and output results to csv
    DEPENDANCIES: Connection Instance to vCenter Server, 
	BUILD ENV===: Powershell Version 5.0.10586.117
    LICENCE=====: GNU GENERAL PUBLIC LICENSE
    VMWAREVersion 5.0, 6.x, 7.x Untested
    KB: o-> https://ss64.com/ps/syntax-datatypes.html
        o-> https://www.compart.com/en/unicode/block/U+1F300
        o-> http://www.hjo3.net/bytes.html
        o-> https://pubs.vmware.com/vsphere-51/index.jsp?topic=%2Fcom.vmware.powercli.cmdletref.doc%2FGet-HardDisk.html
	UPDATED=====: 15/11/2017 @ 15:57PM
#>

function 
vmfs-DeepScanReport()
{
    PARAM(
            [string[]]$filter
         )
    # Build Date String for saved local file
    # ======================================  
    $rawdate = (Get-Date | select datetime).datetime
    $formated_date = $rawdate.ToString() -replace ' ','-' -replace ',','' -replace ':','-'

    # DataCenter Hosts are located in
    # ===============================
    $data_center = 'NDC'

    # Save path for the exported .cxv
    # ===============================
    $filename        = 'NDC-Storage-Report-Gold-Storage'
    $local_save_path = 'H:\Reports\VMWare Reports'
    
    # OBJECT 
    # ======
    $report_container = @()
    if($filter -eq $null)
    { $datastores_array = Get-Datastore -Location $data_center }
    else
    { $datastores_array = Get-Datastore -Location $data_center | where { $_.name -like "*$filter*"} }

    $max_ds_count = $datastores_array.count
    # ==========
    # Start Loop
    # ==========
    foreach( $datastore in $datastores_array )
    {     
            #=QUERY STRING=#
            $ds_fpath = 'vmstores:\' + $global:defaultVIServer[0].Name + '@443\' + $data_center + '\' + $datastore.Name
            Write-Host -f Yellow 'Building Query-String for Datastore -[( ' -NoNewline; Write-Host -f Cyan $datastore.Name -NoNewline; Write-Host -F DarkCyan "--[( $ds_fpath"
            #==============#
            
            # ================================ #
            # GET CHILD ELEMENTS OF DATASTORE  #
            Write-Host -f Yellow 'Interating Datastore Child-Items -[( ' -NoNewline; Write-Host -f Cyan $datastore.Name
            Write-Host -f Yellow 'Checking By-Pass Filters ' -NoNewline; Write-Host -f Cyan "*.vSphere-HA*, *.dvsData*, *.naa.*"
            $dataStore_contents = Get-ChildItem $ds_fpath | where { 
                                                                        $_.Name -notlike "*.vSphere-HA*" -and $_.name -notlike "*.dvsData*" -and $_.name -notlike "*.naa.*"
                                                                  }
            $dataStore_contents_max_count = $dataStore_contents.count
            # ================================ #

            # ================================ #
            #   FIRST STAGE - WRITE-PROGRESS   #
            $datastore_name = $datastore.Name
            $percentComplete_stage_1 = [array]::IndexOf($datastores_array, $datastore) / $max_ds_count * 100
            Write-Progress -Activity "Interating Datastore ==> $datastore_name" -PercentComplete $percentComplete_stage_1 -Status "Running => $percentComplete_stage_1% Completed" -Id 2500
            # ================================ #

            foreach($content in $dataStore_contents)
            { 
                    # =========================================
                    # CALCULATE TOTAL SIZE FROM LENGTH PROPERTY
                    # =========================================
                    $vm_folder = $ds_fpath +"\"+ $content.name
                    
                    # BYTE COUNTER
                    # ============
                    $BytesObject = 0
                    

                    # ========================================================
                    write-host -F DarkRed ([char]::ConvertFromUtf32("0x0001F4C2")) -NoNewline; write-host -F DarkCyan "--$content"
                    $totalDSFolderSize = Get-Childitem $vm_folder | % {
                                                                           Write-Host -ForegroundColor Gray "  |--"$_.Name 
                                                                           $BytesObject += $_.length     
                                                                      }
                    #===@KB====1024=============================#                                    
                    if($BytesObject -gt 1024 -and $BytesObject -lt 1048576)
                    {
                        write-host -f gray "Retrieving raw bytes =======[( " -NoNewline; write-host -F Magenta $BytesObject.ToString()" Bytes"
                        $formatted_size = $BytesObject / 1KB; 
                        $formatted_size_rounded = [math]::Round($formatted_size,3)
                        $VMFolderSize = $formatted_size_rounded.ToString();  
                        $VMFS = $VMFolderSize + " KB"
                        write-host -f DarkGreen "Calculating KB => Convert from bytes => KB ======[( " -NoNewline; write-host -F Magenta $VMFS    
                    }
                    #===@MB====1024*1024========================#
                    elseif($BytesObject -gt 1048576 -and $BytesObject -lt 1073741824)
                    {
                        write-host -f gray "Retrieving raw bytes =======[( " -NoNewline; write-host -F Magenta $BytesObject.ToString()" Bytes"
                        $formatted_size = $BytesObject / 1MB; 
                        $formatted_size_rounded = [math]::Round($formatted_size,3)
                        $VMFolderSize = $formatted_size_rounded.ToString(); 
                        $VMFS = $VMFolderSize + " MB"
                        write-host -f DarkGreen "Calculating MB => Convert from bytes => MB ======[( " -NoNewline; write-host -F Magenta $VMFS                         
                    }
                    #===@GB=====1024*1024*1024==================#
                    elseif($BytesObject -gt 1073741824 -and $BytesObject -lt 1099511627776)
                    {
                        write-host -f gray "Retrieving raw bytes =======[( " -NoNewline; write-host -F Magenta $BytesObject.ToString()" Bytes"
                        $formatted_size = $BytesObject / 1GB; 
                        $formatted_size_rounded = [math]::Round($formatted_size,3)
                        $VMFolderSize = $formatted_size_rounded.ToString(); 
                        $VMFS = $VMFolderSize + " GB"
                        write-host -f DarkGreen "Calculating GB => Convert from bytes => GB ======[( " -NoNewline; write-host -F Magenta $VMFS                         
                    }
                    #===@TB=====1024*1024*1024*1024=============#
                    elseif($BytesObject -gt 1099511627776)
                    {
                        write-host -f gray "Retrieving raw bytes =======[( " -NoNewline; write-host -F Magenta $BytesObject.ToString()" Bytes"
                        $formatted_size = $BytesObject / 1TB; 
                        $formatted_size_rounded = [math]::Round($formatted_size,3)
                        $VMFolderSize = $formatted_size_rounded.ToString(); 
                        $VMFS = $VMFolderSize + " TB" 
                        write-host -f DarkGreen "Calculating TB => Convert from bytes => TB ======[( " -NoNewline; write-host -F Magenta $VMFS                         
                    }
                    else
                    {
                        $VMFS = $BytesObject.ToString()
                        write-host -f DarkGreen "Skipping  Byte Convertion => Total Bytes less than 1MB ===[( " -NoNewline; write-host -F Magenta $VMFS                         

                    }
                    
                    # Seperator
                    # --------
                    write-host -f green 'Folder Size calculation completed ===> Building VM Object...'        
                    
                    if($vm_result = Get-VM | ? { $vmName = $content.Name; $_.Name -like "*$vmName*"} -ErrorAction SilentlyContinue)
                    {
                       Write-Host -F Gray 'Checking VM Folder ->> ' -NoNewline; write-host -F Yellow $vm_result.Name -NoNewline; Write-Host -F Gray ' <=== on ===> ' -NoNewline; Write-Host -ForegroundColor Cyan $datastore

                       $report_container += New-Object -TypeName PSObject -Property @{
               
                                                                                       ConStat = 'Registed-in-vCenter'
                                                                                       Container = $content.Name
                                                                                       VMName = $vm_result.Name
                                                                                       DataStore = $content.Datastore
                                                                                       PowerState = $vm_result.PowerState
                                                                                       VMVersion = $vm_result.Version
                                                                                       MemoryGB = $vm_result.MemoryGB
                                                                                       GuestId = $vm_result.GuestId
                                                                                       LastWriteTime = $content.LastWriteTime
                                                                                       UsedSpaceGB = $VMFS
                                                                                       PSpaceGB = [math]::Round($vm_result.ProvisionedSpaceGB)
                                                                                      }

                    } # END IF
                    else
                    {
                       Write-Host -F Gray 'Non-Registered-VM ->> ' -NoNewline; write-host -F Red $content.Name -NoNewline; Write-Host -F Gray ' <=== on ===> ' -NoNewline; Write-Host -ForegroundColor Cyan $datastore                      
                       $report_container += New-Object -TypeName PSObject -Property @{
               
                                                                                       ConStat = 'Orphaned-VM'
                                                                                       Container = $content.Name
                                                                                       VMName = '-------'
                                                                                       DataStore = $content.Datastore
                                                                                       PowerState = '-------'
                                                                                       VMVersion = '-------'
                                                                                       MemoryGB = '-------'
                                                                                       GuestId = '-------'
                                                                                       LastWriteTime = $content.LastWriteTime
                                                                                       UsedSpaceGB = $VMFS
                                                                                       PSpaceGB = '-------'
                                                                                     }
                   }

            
                    # ================================ #
                    #   SECOND STAGE - WRITE-PROGRESS  #
                    $percentComplete_stage_2 = [array]::IndexOf($dataStore_contents, $content) / $dataStore_contents_max_count * 100
                    Write-Progress -Activity "Calulating Folder Size: $vm_folder" -PercentComplete $percentComplete_stage_2 -Status "Running => $percentComplete_stage_2% Completed" -ParentId 2500
                    # ================================ #
           
            }#@END SECOND FOREACH
            
    }#@END FIRST FOREACH

    # ================================================================================= #
        $report_container | FT
        $report_container | Export-Csv "$local_save_path\$filename-$formated_date.csv"
        write-host -f green "EXPORTED REPORT===> [ $local_save_path\$filename-$formated_date.csv ]"
    # ================================================================================= #

}#@END FUNCTION
