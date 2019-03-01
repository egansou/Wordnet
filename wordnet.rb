require_relative "graph.rb"

# Author : Enock Gansou
class Synsets

    def initialize
        @synsets = Hash.new
    end

    def allKeys
        @synsets.keys
    end

    def load(synsets_file)
        f =  File.open(synsets_file, 'r') 
        i = 0 
        checked_id = Array.new  
        failing_lines = Array.new 
        f.each_line { |line| 
        	line.delete!("\n")
            line.strip
            info = line.split(' ') 
        	i += 1  
        	if (!(line =~ (/^id: (\d+) synset: [\w\'\.\-]+(,[\w\'\.\-]+)*/)) && line.length != 4) 
        		failing_lines.push(i) 
        	else  
        		
        		id = info[1].to_i 
        		if @synsets.key?(id) || checked_id.include?(id) 
        			failing_lines.push(i) 
        		end   
        		checked_id.push(id)        
        	end 
        } 
        f.close 

        if(failing_lines.empty?)
            f =  File.open(synsets_file, 'r')
            f.each_line { |line|
            	line.delete!("\n")
            	line.strip
                info = line.split(' ')
                id = info[1].to_i
                nouns = info[3].split(",")
                addSet(id, nouns)

            }
            f.close
            return nil
        else
            return failing_lines
        end 
    end

    def addSet(synset_id, nouns)
        if (synset_id < 0 || nouns.empty? || @synsets.key?(synset_id))
            return false 
        else
            @synsets[synset_id] = nouns
            return true
        end
    end

    def lookup(synset_id)
        if(@synsets.key?(synset_id))
            return @synsets[synset_id].sort
        else 
            return Array.new
        end
    end

    def findSynsets(to_find)

        if (to_find.is_a?(String))
          arr = Array.new 
          @synsets.each {|synset_id, nouns|  arr.push(synset_id) if @synsets[synset_id].include?(to_find)} 
          return arr

      elsif (to_find.is_a?(Array))
        hashing = Hash.new
        to_find.each { |noun|
            arr = Array.new
            @synsets.each {|synset_id, nouns|  arr.push(synset_id) if @synsets[synset_id].include?(noun)}

            hashing[noun] = arr }
            return hashing
        else 
            return nil
        end
    end
end

class Hypernyms
    def initialize
        @hypernyms = Graph.new
    end

    def allKeys
        @hypernyms.vertices
    end

    def load(hypernyms_file)
        f =  File.open(hypernyms_file, 'r')
        i = 0
        failing_lines = Array.new
        f.each_line { |line|
        	line.delete!("\n")
        	line.strip
        	info = line.split(' ')
            i += 1 
            if(!(line =~ (/^from: (\d+) to: (\d+)(,\d+)*/)) && line != 4)
                failing_lines.push(i) 
            else 
                source = info[1].to_i
                duplicate = 0
                destinations =info[3].split(",")
                destinations.each { |destination| duplicate = 1 if destination == source }
                if  duplicate == 1 then failing_lines.push(i) end
            end  
        } 
        f.close

        if(failing_lines.empty?)
            f =  File.open(hypernyms_file, 'r')
            f.each_line { |line|
            	line.delete!("\n")
        		line.strip
                info = line.split(' ')
                source = info[1].to_i
                destinations =info[3].split(",")
                destinations.each { |destination|  
                    addHypernym(source, destination.to_i) } 
            }
            f.close
            return nil
        else
            return failing_lines
        end 
    end

    def addHypernym(source, destination)
        if(source < 0 || destination < 0 || source == destination)
            return false  
        else 
            if !@hypernyms.hasVertex?(source)  
                @hypernyms.addVertex(source)
            end

            if !@hypernyms.hasVertex?(destination)
                @hypernyms.addVertex(destination)
            end

            if !@hypernyms.hasEdge?(source, destination)
                @hypernyms.addEdge(source, destination) 
            end
            return true
        end
    end

    def lca(id1, id2)
        first = Array.new
        second = Array.new 
        list = Hash.new
        ancestors = Array.new

        if (!@hypernyms.hasVertex?(id1) || !@hypernyms.hasVertex?(id2))
            return nil
        end

        first = @hypernyms.bfs(id1)
        second = @hypernyms.bfs(id2)
        first.each {|vertex, distance|  
            if second.include?(vertex)
                list[vertex] = distance + second[vertex] #compute the total distance 
            end
        }
        min = list.values.min

        list.each {|vertex, total|  
            if total == min 
                ancestors.push(vertex)
            end
        }
        return ancestors
    end
end

class CommandParser
    def initialize
        @synsets = Synsets.new
        @hypernyms = Hypernyms.new
    end

    def parse(command)
        hash = Hash.new

        command.delete!("\n")
        command.strip

        filef = /^[\w\/\-\.]+/
        numf = /^(\d+)/
        stringf = /^[\w\'\.\-]+/
        findmanyf = /^[\w\'\.\-]+(,[\w\'\.\-]+)*/

        info = command.split(' ')

        if(info[0] == "load")
            hash[:recognized_command] = :load
            if( info.length == 3 && info[1] =~ filef && info[2] =~ filef) 

            	dup1 = Marshal.load( Marshal.dump(@synsets) )
            	dup2 = Marshal.load( Marshal.dump(@hypernyms))
            	count = 0
            	
            	synsLoad = dup1.load(info[1])
            	hyperload = dup2.load(info[2])

            	if ( synsLoad == nil && hyperload == nil )
            		dup2.allKeys.each {|key| 
            			if !(dup1.allKeys.include?(key))
            				count = 1
            				break
            			end
            		}
            	end

                if ( synsLoad == nil && hyperload == nil && count == 0)
                    @synsets.load(info[1])
                    @hypernyms.load(info[2])
                    hash [:result] = true 
                else
                    hash [:result] = false 
                end
            else 
                hash [:result] = :error
            end

        elsif (info[0] == "lookup")
            hash[:recognized_command] = :lookup
            if( info.length == 2 && info[1] =~ numf && info[1].to_i >= 0 )
                hash[:result] = @synsets.lookup(info[1].to_i)
            else 
                hash [:result] = :error
            end

        elsif (info[0] == "find")
            hash[:recognized_command] = :find
            if( info.length == 2 && info[1] =~ stringf )
                hash[:result] = @synsets.findSynsets(info[1])
            else 
                hash [:result] = :error
            end

        elsif (info[0] == "findmany")
            hash[:recognized_command] = :findmany
            
            if( info.length == 2 &&  info[1] =~ findmanyf)
            	data = info[1].split(",")
                hash[:result] = @synsets.findSynsets(data)
            else 
                hash [:result] = :error
            end

        elsif (info[0] == "lca")
            hash[:recognized_command] = :lca
            if( info.length == 3 && info[1] =~numf && info[2] =~ numf && info[1].to_i >= 0 && info[2].to_i >= 0)
                hash[:result] = @hypernyms.lca(info[1].to_i, info[2].to_i)
            else 
                hash [:result] = :error
            end

        else 
            hash[:recognized_command] = :invalid
        end
   
        return hash
    end
end
