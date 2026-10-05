function cleanupParallelHydraulics()

    pool = gcp('nocreate');

    if isempty(pool)
        return;
    end

    spmd
        workerEpanetBatchEvaluate('cleanup');
    end

end