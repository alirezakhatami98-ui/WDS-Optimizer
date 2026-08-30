function tempInpPath = createTempInpFile(inpFilePath)

    try
        tempInpPath = 'C:\temp_network.inp';
        copyfile(inpFilePath, tempInpPath, 'f');
    catch
        tempInpPath = fullfile(pwd, 'temp_network.inp');
        copyfile(inpFilePath, tempInpPath, 'f');
    end

end