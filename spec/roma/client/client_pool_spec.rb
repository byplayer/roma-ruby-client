# frozen_string_literal: true

require File.expand_path(File.join('..', '..', 'spec_helper'),
                         File.dirname(__FILE__))

describe Roma::Client::ClientPool do # rubocop:disable BlockLength
  def test_nodes
    %w[localhost_11311 localhost_11411]
  end

  context 'Singleton' do
    subject { Roma::Client::ClientPool.instance(:test) }
    it do
      expect(subject.class).to eq(Roma::Client::ClientPool)
    end

    it do
      expect(subject).to eq(Roma::Client::ClientPool.instance(:test))
    end

    it do
      expect(subject).not_to eq(Roma::Client::ClientPool.instance(:test2))
    end

    it do
      # rubocop:disable LineLength
      expect { Roma::Client::ClientPool.new }.to(
        raise_error(NoMethodError,
                    "private method `new' called for Roma::Client::ClientPool:Class")
      )
      # rubocop:enable LineLength
    end
  end

  context 'max pool size of default' do
    subject { Roma::Client::ClientPool.instance(:test) }
    it { expect(subject.max_pool_size).to eq(1) }
  end

  context 'set max pool size ' do
    it do
      pool = Roma::Client::ClientPool.instance(:test)
      expect(pool.max_pool_size).to eq(1)
      pool.max_pool_size = 3
      expect(pool.max_pool_size).to eq(3)

      pool2 = Roma::Client::ClientPool.instance(:test2)
      expect(pool2.max_pool_size).to eq(1)
    end
  end

  context 'servers default' do
    subject { Roma::Client::ClientPool.instance(:test) }
    it { expect(subject.servers).to be_nil }
  end

  context 'servers set' do
    it {
      pool = Roma::Client::ClientPool.instance(:test_servers_set)
      expect(pool.servers).to be_nil
      nodes = test_nodes
      pool.servers = nodes
      expect(pool.servers).to eq(nodes)

      instance = Roma::Client::ClientPool.instance(:test_ini_nodes_set2)
      expect(instance.servers).to be_nil
    }
  end

  context 'client' do
    subject do
      pool = Roma::Client::ClientPool.instance(:test_client)
      pool.servers = test_nodes
      pool
    end

    it { expect(subject.pool_count).to eq(0) }
    it do
      client = subject.client
      expect(client.class).to eq(Roma::Client::RomaClient)
      subject.push_client(client)
      expect(subject.pool_count).to eq(1)
    end

    it do
      client = subject.client
      nodes = client.rttable.nodes
      expect(nodes).to eq(test_nodes)
    end
  end

  context 'client multi pool' do
    subject do
      pool = Roma::Client::ClientPool.instance(:test_client2)
      pool.servers = test_nodes
      pool
    end

    it do
      expect(subject.pool_count).to eq(0)
      client = subject.client
      expect(client).not_to be_nil

      client2 = subject.client
      expect(client2).not_to be_nil

      subject.push_client(client)
      expect(subject.pool_count).to eq(1)

      subject.push_client(client2)
      expect(subject.pool_count).to eq(1)

      expect(client).to eq(subject.client)
      expect(subject.pool_count).to eq(0)
    end
  end

  context 'plugin modules' do # rubocop:disable BlockLength
    # plugin for test
    module TestPlugin
      def test_plugin
        'test_plugin'
      end
    end

    # plugin for test
    module TestPlugin2
      def test_plugin2
        'test_plugin2'
      end
    end

    it do
      pool = Roma::Client::ClientPool.instance(:pm_test)
      expect(pool.plugin_modules).to be_nil

      pool.add_plugin_module(TestPlugin)
      expect(pool.plugin_modules).not_to be_nil
      expect(pool.plugin_modules.size).to eq(1)
      pool.plugin_modules[0] == TestPlugin
    end

    it do
      pool = Roma::Client::ClientPool.instance(:pms_test)
      expect(pool.plugin_modules).to be_nil

      pool.plugin_modules = [TestPlugin, TestPlugin2]
      expect(pool.plugin_modules.size).to eq(2)
      expect(pool.plugin_modules[0]).to eq(TestPlugin)
      expect(pool.plugin_modules[1]).to eq(TestPlugin2)
    end

    it do
      pool = Roma::Client::ClientPool.instance(:pms_test2)
      pool.servers = test_nodes
      expect(pool.plugin_modules).to be_nil

      pool.plugin_modules = [TestPlugin, TestPlugin2]
      client = pool.client
      expect(client).not_to be_nil
      expect(client.test_plugin).to eq('test_plugin')
      expect(client.test_plugin2).to eq('test_plugin2')
    end
  end

  context 'default type' do
    subject { Roma::Client::ClientPool.instance }
    it { expect(subject).not_to be_nil }
    it { expect(subject.class).to eq(Roma::Client::ClientPool) }
    it { expect(subject).to eq(Roma::Client::ClientPool.instance(:default)) }
  end

  context 'support hash name' do
    after(:all) do
      Roma::Client::ClientPool.instance.default_hash_name = 'roma'
    end

    subject do
      pool = Roma::Client::ClientPool.instance
      pool.servers = test_nodes
      pool
    end

    it { expect(subject.default_hash_name).to eq('roma') }
    it do
      subject.default_hash_name = 'new_name'
      expect(subject.default_hash_name).to eq('new_name')
      expect(Roma::Client::ClientPool
              .instance.default_hash_name).to eq('new_name')
      expect(Roma::Client::ClientPool
        .instance(:other).default_hash_name).to eq('roma')

      client = subject.client
      expect(client.default_hash_name).to eq('new_name')
    end
  end

  context 'release' do
    subject do
      pool = Roma::Client::ClientPool.instance(:release_test)
      pool.servers = test_nodes
      pool
    end

    it do
      expect(subject.pool_count).to eq(0)
      subject.client do |client|
      end

      expect(subject.pool_count).to eq(1)
      expect(subject.release).to eq(true)
      expect(subject.pool_count).to eq(0)
    end
  end

  context 'client block' do # rubocop:disable BlockLength
    before(:each) do
      pool = Roma::Client::ClientPool.instance(:client_block)
      pool.release
    end

    subject do
      pool = Roma::Client::ClientPool.instance(:client_block)
      pool.servers = test_nodes
      pool
    end

    it 'use block' do
      expect(subject.pool_count).to eq(0)
      subject.client do |client|
        expect(client.set('test', 'value')).to eq('STORED')
      end
      expect(subject.pool_count).to eq(1)
    end

    it 'raise exception in block, but pool certainly' do
      expect(subject.pool_count).to eq(0)
      subject.client do |client|
        expect(client.set('test', 'value')).to eq('STORED')
      end
      expect(subject.pool_count).to eq(1)

      expect do
        subject.client do |_client|
          raise 'test error'
        end
      end.to raise_error RuntimeError, 'test error'

      expect(subject.pool_count).to eq(1)
    end
  end

  context 'start sync routing proc' do
    it do
      pool = Roma::Client::ClientPool.instance(:sync_test)
      pool.servers = test_nodes
      old_thread_count = Thread.list.length
      pool.client do |c|
      end

      expect(pool.pool_count).to eq(1)
      expect(Thread.list.length).to eq(old_thread_count + 1)
    end

    it do
      pool = Roma::Client::ClientPool.instance(:no_sync_test)
      pool.servers = test_nodes
      pool.start_sync_routing_proc = false
      old_thread_count = Thread.list.length
      pool.client do |c|
      end

      expect(pool.pool_count).to eq(1)
      expect(Thread.list.length).to eq(old_thread_count)
    end
  end

  context 'release all' do
    it do
      pool = Roma::Client::ClientPool.instance(:release_all_1)
      pool.servers = test_nodes
      pool.client do |c|
      end
      expect(Roma::Client::ClientPool
              .instance(:release_all_1).pool_count).to eq(1)

      pool = Roma::Client::ClientPool.instance(:release_all_2)
      pool.servers = test_nodes
      pool.client do |c|
      end
      expect(pool.pool_count).to eq(1)
      expect(Roma::Client::ClientPool
              .instance(:release_all_2).pool_count).to eq(1)

      Roma::Client::ClientPool.release_all
      expect(Roma::Client::ClientPool
              .instance(:release_all_1).pool_count).to eq(0)
      expect(Roma::Client::ClientPool
              .instance(:release_all_2).pool_count).to eq(0)

      expect(Roma::Client::ClientPool
              .instance(:release_all_1).servers).to eq(test_nodes)
      expect(Roma::Client::ClientPool
              .instance(:release_all_2).servers).to eq(test_nodes)
    end
  end
end
