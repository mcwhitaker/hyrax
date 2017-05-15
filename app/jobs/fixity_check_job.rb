class FixityCheckJob < ActiveJob::ApplicationJob
  # A Job class that runs a fixity check (using ActiveFedora::FixityService,
  # which contacts fedora and requests a fixity check), and stores the results
  # in an ActiveRecord ChecksumAuditLog row. It also prunes old ChecksumAuditLog
  # rows after creating a new one, to keep old ones you don't care about from
  # filling up your db.
  #
  # The uri passed in is a fedora URI that fedora can run fixity check on.
  # It's normally a version URI like:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  #
  # But could theoretically be any URI fedora can fixity check on, like a file uri:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content
  #
  # The file_set_id and file_id are used only for logging context in the
  # ChecksumAuditLog, and determining what old ChecksumAuditLogs can
  # be pruned.
  #
  # If calling async as a background job, return value is irrelevant, but
  # if calling sync with `perform_now`, returns the ChecksumAuditLog
  # record recording the check.
  #
  # @param uri [String] uri - of the specific file/version to fixity check
  # @param file_set_id [FileSet] the id for FileSet parent object of URI being checked.
  # @param file_id [String] File#id, used for logging/reporting.
  def perform(uri, file_set_id:, file_id:)
    log = run_check(file_set_id, file_id, uri)

    unless log.passed?
      if Hyrax.config.callback.set?(:after_fixity_check_failure)
        file_set = ::FileSet.find(file_set_id)
        login = file_set.depositor
        user = User.find_by_user_key(login)
        Hyrax.config.callback.run(:after_fixity_check_failure,
                                  file_set,
                                  user,
                                  log.created_at)
      end
    end
    log
  end

  protected



    def run_check(file_set_id, file_id, uri)
      begin
        fixity_ok = ActiveFedora::FixityService.new(uri).check
      rescue Ldp::NotFound
        error_msg = 'resource not found'
      end

      if fixity_ok
        passing = 1
        ChecksumAuditLog.prune_history(file_set_id, file_id)
      else
        logger.warn "***AUDIT*** Audit failed for #{uri} #{error_msg}"
        passing = 0
      end
      ChecksumAuditLog.create!(pass: passing, file_set_id: file_set_id, checked_uri: uri, file_id: file_id)
    end

  private

    def logger
      ActiveFedora::Base.logger
    end
end
