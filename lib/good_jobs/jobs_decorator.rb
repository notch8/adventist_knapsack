module JobStatistics
  def completed_jobs_statistics(start_at: 1.day.ago, end_at: 1.minute.ago)
    # Get the completed jobs from the last 1 day
    completed_jobs = GoodJob::Job.where("finished_at >= ? and finished_at < ?", start_at, end_at)

    # Group the jobs by job class name
    grouped_jobs = completed_jobs.group_by do |j|
      j.serialized_params['job_class']
    end

    # Initialize the result hash
    result = {}

    # Iterate through each group
    grouped_jobs.each do |job_class, jobs|
      # Calculate the count of jobs
      count = jobs.size

      # Calculate the average time taken to complete the jobs
      total_time = jobs.sum { |job| job.finished_at - job.performed_at }
      average_time = total_time / count

      # Store the result in the hash
      result[job_class] = { count:, average_time: }
    end

    result
  end
end
GoodJob::Job.singleton_class.prepend(JobStatistics)
