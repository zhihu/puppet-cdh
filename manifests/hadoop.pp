#
# == Class cdh::hadoop
#
# Installs the main Hadoop/HDFS packages and config files.
# By default this will set Hadoop config files to run YARN (MapReduce 2).
#
# This assumes that your JBOD mount points are already
# formatted and mounted at the locations listed in $datanode_mounts.
#
# dfs.datanode.data.dir will be set to each of ${dfs_data_dir_mounts}/$data_path
# yarn.nodemanager.local-dirs will be set to each of ${dfs_data_dir_mounts}/$yarn_local_path
# yarn.nodemanager.log-dirs will be set to each of ${dfs_data_dir_mounts}/$yarn_logs_path
#
# == Parameters
#   $namenode_hosts                  - Array of NameNode host(s).  The first entry in this
#                                      array will be the primary NameNode.  The primary NameNode
#                                      will also be used as the host for the historyserver, proxyserver,
#                                      and resourcemanager.   Use multiple hosts hosts if you
#                                      configuring Hadoop with HA NameNodes.
#   $dfs_name_dir                    - Path to hadoop NameNode name directory.  This
#                                      can be an array of paths or a single string path.
#   $cluster_name                    - Arbitrary logical HDFS cluster name.  This will be used
#                                      as the nameserivce id if you set $ha_enabled to true.
#                                      Default: 'cdh'.
#   $mapreduce_enabled               - Set to false if you doesn't need setup MapReduce (YARN or MRv1), i.e. only HDFS installed.  Default: true.
#   $journalnode_hosts               - Array of JournalNode hosts.  If this is provided,
#                                      Hadoop will be configured to expect to have
#                                      a primary NameNode as well as at least
#                                      one Standby NameNode for use in high availibility mode.
#   $dfs_journalnode_edits_dir       - Path to JournalNode edits dir.  This will be
#                                      ignored if $ha_enabled is false.
#
#   $short_circuit_reads_enabled     - Set to true if your need enable
#                                      short-circuit local reads.
#                                      This is required if you want to
#                                      use Impala.  Default: false
#   $block_location_tracking_enabled - Set to true if your need enable block
#                                      location tracking.
#                                      This is required if you want to
#                                      use Impala.  Default: false
#   $azkaban_enabled                 - Set to true if you need integrate Hadoop
#                                      with Azkaban (will set azkaban as Hadoop
#                                      proxy user and group).  Default: false.
#
#   $datanode_mounts                 - Array of JBOD mount points.  Hadoop datanode and
#                                      mapreduce/yarn directories will be here.
#   $dfs_data_path                   - Path relative to JBOD mount point for HDFS data directories.
#   $enable_jmxremote                - enables remote JMX connections for all Hadoop services.
#                                      Ports are not currently configurable.  Default: true.
#   $yarn_local_path                 - Path relative to JBOD mount point for yarn local directories.
#   $yarn_logs_path                  - Path relative to JBOD mount point for yarn log directories.
#   $dfs_block_size                  - HDFS block size in bytes.  Default 64MB.
#   $balance_speed                   - HDFS balance band width Per Sec, type: byte.
#   $io_file_buffer_size
#   $map_tasks_maximum
#   $reduce_tasks_maximum
#   $mapreduce_job_reuse_jvm_num_tasks
#   $reduce_parallel_copies
#   $map_memory_mb
#   $reduce_memory_mb
#   $mapreduce_system_dir
#   $mapreduce_task_io_sort_mb
#   $mapreduce_task_io_sort_factor
#   $mapreduce_map_java_opts
#   $mapreduce_child_java_opts
#   $yarn_app_mapreduce_am_resource_mb             - The amount of memory the MR AppMaster needs.
#   $yarn_app_mapreduce_am_command_opts            - Java opts for the MR App Master processes. The following symbol, if
#                                                   present, will be interpolated: @taskid@ is replaced by current TaskID
#   $mapreduce_shuffle_memory_limit_percent        - Maximum percentage of the in-memory limit that a single shuffle can
#                                                   consume, Default: 0.25.
#   $mapreduce_shuffle_port
#   $mapreduce_intermediate_compression            - If true, intermediate MapReduce data
#                                                    will be compressed.  Default: true.
#   $mapreduce_intermediate_compression_codec      - Codec class to use for intermediate compression.
#                                                    Default: org.apache.hadoop.io.compress.DefaultCodec
#   $mapreduce_output_compession                   - If true, final output of MapReduce
#                                                    jobs will be compressed. Default: false.
#   $mapreduce_output_compession_codec             - Codec class to use for final output compression.
#                                                    Default: org.apache.hadoop.io.compress.DefaultCodec
#   $mapreduce_output_compession_type              - Whether to output compress on BLOCK or RECORD level.
#                                                    Default: RECORD
#   $yarn_resourcemanager_recovery_enabled         - The flag to enable/disable this feature, Default false
#                                                    If this configuration property is set to true, RM will enable
#                                                    the RM-restart functionality.
#   $yarn_nodemanager_resource_cpu_vcores          - Number of CPU cores that can be allocated for containers.
#   $yarn_nodemanager_resource_memory_mb
#   $yarn_scheduler_minimum_allocation_mb          - The minimum allocation for every container request at the RM,
#                                                    in MBs. Memory requests lower than this won't take effect, and
#                                                    the specified value will get allocated at minimum.
#   $yarn_scheduler_maximum_allocation_mb          - The maximum allocation for every container request at the RM,
#                                                    in MBs. Memory requests higher than this won't take effect, and
#                                                    will get capped to this value.
#   $yarn_scheduler_minimum_allocation_vcores      - The minimum allocation for every container
#                                                    request at the RM, in terms of virtual CPU
#                                                    cores. Requests lower than this won't take
#                                                    effect, and the specified value will get allocated the minimum.
#   $yarn_scheduler_maximum_allocation_vcores      - The maximum allocation for every container
#                                                    request at the RM, in terms of virtual CPU
#                                                    cores. Requests higher than this won't take
#                                                    effect, and will get capped to this value.
#   $yarn_resourcemanager_scheduler_class          - If you change this (e.g. to
#                                                    FairScheduler), you should also provide
#                                                    your own scheduler config .xml files
#                                                    outside of the cdh module.
#   $yarn_aux_services_spark_shuffle_enabled       - If enable spark_shuffle service.  Default: false
#
#   $hadoop_heapsize                               - -Xmx for NameNode and DataNode.  Default: undef
#   $yarn_heapsize                                 - -Xmx for YARN Daemons.           Default: undef
#   $ganglia_hosts                                 - Set this to an array of ganglia host:ports
#                                                    if you want to enable ganglia sinks in hadoop-metrics2.properites
#   $net_topology_script_template                  - Puppet ERb template path  to script that will be
#                                                    invoked to resolve node names to row or rack assignments.
#                                                    Default: undef
#   $gelf_logging_enabled                          - Set this to true in order to configure GELF logging output, for Logstash
#                                                  - Needs: libjson-simple-java (Debian package)
#                                                  - Needs: logstash-gelf.jar (https://github.com/mp911de/logstash-gelf/releases)
#   $gelf_logging_host                             - Destination host for GELF output. Default is localhost.
#   $gelf_logging_port                             - Destination port for GELF output. Default is 12201.
#   $fair_scheduler_template                       - The fair-scheduler.xml queue configuration template.
#                                                    If you set this to false or undef, FairScheduler will
#                                                    be disabled.  Default: cdh/hadoop/fair-scheduler.xml.erb
#   $fair_user_as_default_queue                    - Whether to use the username associated with the
#                                                    allocation as the default queue name. Default: false
#   $fair_preemption                               - Whether to use preemption.  Default: false
#   $fair_preemption_cluster_utilization_threshold - The utilization threshold after which
#                                                    preemption kicks in.  Default: undef
#   $fair_locality_threshold_node                  - For applications that request containers
#                                                    on particular nodes, the number of scheduling
#                                                    opportunities since the last container
#                                                    assignment to wait before accepting a
#                                                    placement on another node.  Default: undef
#   $fair_locality_threshold_rack                  - For applications that request containers
#                                                    on particular racks, the number of scheduling
#                                                    opportunities since the last container
#                                                    assignment to wait before accepting a
#                                                    placement on another rack.  Default: undef
#   $queue_max_apps_default                        - Sets the default running app limit for queues.  Default: 50
#   $default_fair_share_preemption_timeout         - Sets the fair share preemption timeout (second)
#                                                    for the root queue.  Default: 30
#   $default_fair_share_preemption_threshold       - Sets the fair share preemption threshold
#                                                    for the root queue.  Default: 0.5
#   $default_queue_scheduling_policy               - Sets the default scheduling policy for queues.  Default: fair
#
#   $hadoop_classpath                              - Add addtitional classpath to HADOOP_CLASSPATH which set in hadoop-env.sh.
#   $java_library_path                             - Add addtitional library path to JAVA_LIBRARY_PATH which set in hadoop-env.sh.
#   $ld_library_path                               - Add addtitional library path to LD_LIBRARY_PATH which set in hadoop-env.sh.
#   $lzo_enabled                                   - Set true when you add LZO compress.
#   $io_compression_codec_lzo_class                - Write LZO class name.            Default: com.hadoop.compression.lzo.LzoCodec
#   $io_compression_codecs                         - A list of the compression codec classes that can be used for compression/decompression.
#
class cdh::hadoop(
    $namenode_hosts,
    $dfs_name_dir,
    $cluster_name                                  = $::cdh::hadoop::defaults::cluster_name,
    $mapreduce_enabled                             = $::cdh::hadoop::defaults::mapreduce_enabled,
    $journalnode_hosts                             = $::cdh::hadoop::defaults::journalnode_hosts,
    $dfs_journalnode_edits_dir                     = $::cdh::hadoop::defaults::dfs_journalnode_edits_dir,

    $short_circuit_reads_enabled                   = $::cdh::hadoop::defaults::short_circuit_reads_enabled,
    $block_location_tracking_enabled               = $::cdh::hadoop::defaults::block_location_tracking_enabled,
    $azkaban_enabled                               = $::cdh::hadoop::defaults::azkaban_enabled,

    $datanode_mounts                               = $::cdh::hadoop::defaults::datanode_mounts,
    $dfs_data_path                                 = $::cdh::hadoop::defaults::dfs_data_path,

    $yarn_local_path                               = $::cdh::hadoop::defaults::yarn_local_path,
    $yarn_logs_path                                = $::cdh::hadoop::defaults::yarn_logs_path,
    $dfs_block_size                                = $::cdh::hadoop::defaults::dfs_block_size,
    $enable_jmxremote                              = $::cdh::hadoop::defaults::enable_jmxremote,
    $webhdfs_enabled                               = $::cdh::hadoop::defaults::webhdfs_enabled,
    $httpfs_enabled                                = $::cdh::hadoop::defaults::httpfs_enabled,
    $io_file_buffer_size                           = $::cdh::hadoop::defaults::io_file_buffer_size,
    $balance_speed                                 = $::cdh::hadoop::defaults::balance_speed,
    $mapreduce_system_dir                          = $::cdh::hadoop::defaults::mapreduce_system_dir,
    $mapreduce_map_tasks_maximum                   = $::cdh::hadoop::defaults::mapreduce_map_tasks_maximum,
    $mapreduce_reduce_tasks_maximum                = $::cdh::hadoop::defaults::mapreduce_reduce_tasks_maximum,
    $mapreduce_job_reuse_jvm_num_tasks             = $::cdh::hadoop::defaults::mapreduce_job_reuse_jvm_num_tasks,
    $mapreduce_reduce_shuffle_parallelcopies       = $::cdh::hadoop::defaults::mapreduce_reduce_shuffle_parallelcopies,
    $mapreduce_map_memory_mb                       = $::cdh::hadoop::defaults::mapreduce_map_memory_mb,
    $mapreduce_reduce_memory_mb                    = $::cdh::hadoop::defaults::mapreduce_reduce_memory_mb,
    $yarn_app_mapreduce_am_resource_mb             = $::cdh::hadoop::defaults::yarn_app_mapreduce_am_resource_mb,
    $yarn_app_mapreduce_am_command_opts            = $::cdh::hadoop::defaults::yarn_app_mapreduce_am_command_opts,
    $mapreduce_task_io_sort_mb                     = $::cdh::hadoop::defaults::mapreduce_task_io_sort_mb,
    $mapreduce_task_io_sort_factor                 = $::cdh::hadoop::defaults::mapreduce_task_io_sort_factor,
    $mapreduce_map_java_opts                       = $::cdh::hadoop::defaults::mapreduce_map_java_opts,
    $mapreduce_reduce_java_opts                    = $::cdh::hadoop::defaults::mapreduce_reduce_java_opts,
    $mapreduce_shuffle_port                        = $::cdh::hadoop::defaults::mapreduce_shuffle_port,
    $mapreduce_shuffle_memory_limit_percent        = $::cdh::hadoop::defaults::mapreduce_shuffle_memory_limit_percent,
    $mapreduce_intermediate_compression            = $::cdh::hadoop::defaults::mapreduce_intermediate_compression,
    $mapreduce_intermediate_compression_codec      = $::cdh::hadoop::defaults::mapreduce_intermediate_compression_codec,
    $mapreduce_output_compression                  = $::cdh::hadoop::defaults::mapreduce_output_compession,
    $mapreduce_output_compression_codec            = $::cdh::hadoop::defaults::mapreduce_output_compession_codec,
    $mapreduce_output_compression_type             = $::cdh::hadoop::defaults::mapreduce_output_compression_type,
    $yarn_resourcemanager_recovery_enabled         = $::cdh::hadoop::defaults::yarn_resourcemanager_recovery_enabled,
    $yarn_nodemanager_resource_cpu_vcores          = $::cdh::hadoop::defaults::yarn_nodemanager_resource_cpu_vcores,
    $yarn_nodemanager_resource_memory_mb           = $::cdh::hadoop::defaults::yarn_nodemanager_resource_memory_mb,
    $yarn_scheduler_minimum_allocation_mb          = $::cdh::hadoop::defaults::yarn_scheduler_minimum_allocation_mb,
    $yarn_scheduler_maximum_allocation_mb          = $::cdh::hadoop::defaults::yarn_scheduler_maximum_allocation_mb,
    $yarn_scheduler_minimum_allocation_vcores      = $::cdh::hadoop::defaults::yarn_scheduler_minimum_allocation_vcores,
    $yarn_scheduler_maximum_allocation_vcores      = $::cdh::hadoop::defaults::yarn_scheduler_maximum_allocation_vcores,
    $yarn_aux_services_spark_shuffle_enabled       = $::cdh::hadoop::defaults::yarn_aux_services_spark_shuffle_enabled,

    $fair_scheduler_template                       = $::cdh::hadoop::defaults::fair_scheduler_template,
    $fair_user_as_default_queue                    = $::cdh::hadoop::defaults::fair_user_as_default_queue,
    $fair_preemption                               = $::cdh::hadoop::defaults::fair_preemption,
    $fair_preemption_cluster_utilization_threshold = $::cdh::hadoop::defaults::fair_preemption_cluster_utilization_threshold,
    $fair_locality_threshold_node                  = $::cdh::hadoop::defaults::fair_locality_threshold_node,
    $fair_locality_threshold_rack                  = $::cdh::hadoop::defaults::fair_locality_threshold_rack,
    $queue_max_apps_default                        = $::cdh::hadoop::defaults::queue_max_apps_default,
    $default_fair_share_preemption_timeout         = $::cdh::hadoop::defaults::default_fair_share_preemption_timeout,
    $default_fair_share_preemption_threshold       = $::cdh::hadoop::defaults::default_fair_share_preemption_threshold,
    $default_queue_scheduling_policy               = $::cdh::hadoop::defaults::default_queue_scheduling_policy,

    $hadoop_heapsize                               = $::cdh::hadoop::defaults::hadoop_heapsize,
    $yarn_heapsize                                 = $::cdh::hadoop::defaults::yarn_heapsize,

    $ganglia_hosts                                 = $::cdh::hadoop::defaults::ganglia_hosts,
    $net_topology_script_template                  = $::cdh::hadoop::defaults::net_topology_script_template,
    $gelf_logging_enabled                          = $::cdh::hadoop::defaults::gelf_logging_enabled,
    $gelf_logging_host                             = $::cdh::hadoop::defaults::gelf_logging_host,
    $gelf_logging_port                             = $::cdh::hadoop::defaults::gelf_logging_port,

    $hadoop_classpath                              = $::cdh::hadoop::defaults::hadoop_classpath,
    $java_library_path                             = $::cdh::hadoop::defaults::java_library_path,
    $ld_library_path                               = $::cdh::hadoop::defaults::ld_library_path,
    $lzo_enabled                                   = $::cdh::hadoop::defaults::lzo_enabled,
    $io_compression_codec_lzo_class                = $::cdh::hadoop::defaults::io_compression_codec_lzo_class,
    $io_compression_codecs                         = $::cdh::hadoop::defaults::io_compression_codecs,
) inherits cdh::hadoop::defaults
{
    # If $dfs_name_dir is a list, this will be the
    # first entry in the list.  Else just $dfs_name_dir.
    # This used in a couple of execs throughout this module.
    $dfs_name_dir_main = inline_template('<%= (@dfs_name_dir.class == Array) ? @dfs_name_dir[0] : @dfs_name_dir %>')

    # Set a boolean used to indicate that HA NameNodes
    # are intended to be used for this cluster.  HA NameNodes
    # require the JournalNodes are configured.
    $ha_enabled = $journalnode_hosts ? {
        undef   => false,
        default => true,
    }

    # If $ha_enabled is true, use $cluster_name as $nameservice_id.
    $nameservice_id = $ha_enabled ? {
        true    => $cluster_name,
        default => undef,
    }

    # Config files are installed into a directory
    # based on the value of $cluster_name.
    $config_directory = "/etc/hadoop/conf.${cluster_name}"

    # Parameter Validation:
    if ($ha_enabled and !$journalnode_hosts) {
        fail('Must provide multiple $journalnode_hosts when using HA and setting $nameservice_id.')
    }

    # Assume the primary namenode is the first entry in $namenode_hosts,
    # Set a variable here for reference in other classes.
    $primary_namenode_host = $namenode_hosts[0]
    # This is the primary NameNode ID used to identify
    # a NameNode when running HDFS with a logical nameservice_id.
    # We can't use '.' characters because NameNode IDs
    # will be used in the names of some Java properties,
    # which are '.' delimited.
    $primary_namenode_id   = inline_template('<%= @primary_namenode_host.tr(\'.\', \'-\') %>')

    package { 'hadoop-client':
        ensure => 'installed'
    }

    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hadoop-client'],
    }
    cdh::alternative { 'hadoop-conf':
        link    => '/etc/hadoop/conf',
        path    => $config_directory,
    }

    # Render net-topology.sh from $net_topology_script_template
    # if it was given.
    $net_topology_script_ensure = $net_topology_script_template ? {
        undef   => 'absent',
        default => 'present',
    }
    $net_topology_script_path = "${config_directory}/net-topology.sh"
    file { $net_topology_script_path:
        ensure  => $net_topology_script_ensure,
        mode    => '0755',
    }
    # Conditionally overriding content attribute since
    # $net_topology_script_template is default undef.
    if ($net_topology_script_ensure == 'present') {
        File[$net_topology_script_path] {
            content => template($net_topology_script_template),
        }
    }

    $fair_scheduler_enabled = $fair_scheduler_template ? {
        undef   => false,
        false   => false,
        default => true
    }
    $fair_scheduler_allocation_file_ensure = $fair_scheduler_enabled ? {
        true  => 'present',
        false => 'absent'
    }
    # FairScheduler can be enabled
    # and this file will be used to configure
    # FairScheduler queues.
    file { "${config_directory}/fair-scheduler.xml":
        ensure  => $fair_scheduler_allocation_file_ensure,
        content => template($fair_scheduler_template)
    }

    # If lzo_enabled set, LZO class will be add to io_compression_codecs
    if $lzo_enabled and (! member($io_compression_codecs, 'com.hadoop.compression.lzo.LzoCodec')) {
        $new_io_compression_codecs = concat($io_compression_codecs, ['com.hadoop.compression.lzo.LzoCodec', 'com.hadoop.compression.lzo.LzopCodec'])
    } else {
        $new_io_compression_codecs = $io_compression_codecs
    }

    file { "${config_directory}/log4j.properties":
        content => template('cdh/hadoop/log4j.properties.erb'),
    }

    file { "${config_directory}/core-site.xml":
        content => template('cdh/hadoop/core-site.xml.erb'),
    }

    file { "$config_directory/hdfs-site.xml":
        content => template('cdh/hadoop/hdfs-site.xml.erb'),
    }

    file { "${config_directory}/hadoop-env.sh":
        content => template('cdh/hadoop/hadoop-env.sh.erb'),
    }

    file { "${config_directory}/mapred-site.xml":
        content => template('cdh/hadoop/mapred-site.xml.erb'),
    }

    file { "${config_directory}/yarn-site.xml":
        content => template('cdh/hadoop/yarn-site.xml.erb'),
    }

    file { "${config_directory}/yarn-env.sh":
        content => template('cdh/hadoop/yarn-env.sh.erb'),
    }

    # Render hadoop-metrics2.properties
    # if we have Ganglia Hosts to send metrics to.
    $hadoop_metrics2_ensure = $ganglia_hosts ? {
        undef   => 'absent',
        default => 'present',
    }
    file { "${config_directory}/hadoop-metrics2.properties":
        ensure  => $hadoop_metrics2_ensure,
        content => template('cdh/hadoop/hadoop-metrics2.properties.erb'),
    }

    # If the current node is meant to be JournalNode,
    # include the journalnode class.  JournalNodes can
    # be started at any time.
    if ($journalnode_hosts and (
            ($::fqdn           and $::fqdn           in $journalnode_hosts) or
            ($::ipaddress      and $::ipaddress      in $journalnode_hosts) or
            ($::ipaddress_eth1 and $::ipaddress_eth1 in $journalnode_hosts))) {
        include cdh::hadoop::journalnode
    }

    # If short-circuit local reads is enabled, ensure domain
    # socket path exists.
    if $short_circuit_reads_enabled {
        $dfs_domain_socket_path_parent = inline_template("<%= File.dirname('${dfs_domain_socket_path}') %>")
        file { "$dfs_domain_socket_path_parent":
            ensure => directory,
            owner  => 'hdfs',
            group  => 'hdfs'
        }
    }
}
