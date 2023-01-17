require 'strscan'
class Sound
    def initialize
        begin
            @formula = []
            file = ARGV[0]
            File.open(file){|f|
                f.each_line{|line|
                  @formula << line
                }
              }
            # puts @formula
        rescue
            puts "ファイルがありません。"
        end
        for i in 0...@formula.length do
            @scanner = StringScanner.new(@formula[i].chomp)
            @keywords = {
                '+' => :add,
                '-' => :sub,
                '*' => :mul,
                '/' => :div,
                '(' => :left_parn,
                ')' => :right_parn,
                '=' => :equal,
                'para' => :para,
                'keepon' => :keepon,
                'visu' => :visu,
                'get' => :get
            }

            # 計算式
            # p eval(expression) #結果を出力

            p sentences()
        end

    end

    def expression()
        result = term()
        token = get_token()
        while token == :add or token == :sub
            result = [token, result, term()]
            p result
            token = get_token()
        end

        unget_token()
        return result
    end

    def term()
        result = factor()
        token = get_token()
        while token == :mul or token == :div
            result = [token, result, factor()]
            p result
            token = get_token()
        end

        unget_token()
        return result
    end

    def factor()
        token = get_token()
        if token.is_a?(Numeric) # 数字だったら
            result = token
        elsif token == :left_parn #（ だったら
            result = expression()
            token = get_token() # 閉じカッコを取り除く(使用しない)
            if token != :right_parn # ) なかったら
                raise Exception, "構文エラー"
            else
                # p token
            end
        end

        return result
    end

    def eval(exp)
        if exp.instance_of?(Array)
            case exp[0]
            when :add
                return eval(exp[1]) + eval(exp[2])
            when :sub
                return eval(exp[1]) - eval(exp[2])
            when :mul
                return eval(exp[1]) * eval(exp[2])
            when :div
                begin
                    return eval(exp[1]) / eval(exp[2])
                rescue => e
                    puts e.message
                end
            end
        else
            return exp
        end
    end

    def parse()
        expression()
    end

    # ソースコードの先頭から、次のtokenを一つ切り出して返す。
    def get_token()
        if scan = @scanner.scan(/\A*([0-9.]+)/) then #数値だったら
            p "数値：#{scan}"
            return scan.to_f
        elsif scan = @scanner.scan(/\A*(#{@keywords.keys.map{|t| Regexp.escape(t)}.join('|')})/) then # 予約語だったら
            p "予約語：#{@keywords[scan]}"
            return @keywords[scan]
        elsif scan = @scanner.scan(/\A[a-zA-Z]+/) then #英字だったら（変数名）
            p "変数：#{scan}"
            return scan
        end
    end

    # tokenを受け取り、ソースコードの先頭にそれを押し戻す。
    def unget_token()
        if !(@scanner.eos?)
            @scanner.unscan
        end
    end

    # 文列
    def sentences()
        unless s = sentence()
            raise Exception, "あるべき文が見つからない"
        end
        
        result = [:block, s]
        while s = sentence()
            result << s
        end
        return result
    end

    def sentence()
        # 代入文、if文、while文、print文
        # elsif token = para()
        #     return token
        # elsif token = keepon()
        #     return token
        if token = visu()
            return token
        elsif token = get()
            return token
        elsif token = assignment()
            return token
        end
    end

    def assignment()
        result = [:assignment]
        token = get_token()
        unless token.instance_of?(String)
            unget_token()
            return nil
        end

        result << [:variable, token]
        unless get_token() == :equal
            raise Exception, "イコールがない"
        end
        unless token = expression()
            raise Exception, "式がない"
        end
        result << token
    end

    # 出力
    def visu()
        unless get_token() == :visu
            unget_token()
            return nil
        end
        result = [:visu]
        # 変数もできるように改良する。
        unless token = eval(expression())
            raise Exception, "式がない"
        end
        result << token
    end
    
    # 入力
    def get()
        unless get_token() == :get
            unget_token()
            return nil
        end
        result = [:get]
        get = gets
        unless get
            rails Exception, "入力がない"
        end
        result << get
    end

    # for文
    def keepon(formula, sentence)
        n = formula # n回繰り返す
        sentence # 繰り返したい式
        for i in 0..n.to_i do
            sentence
            # これじゃできなさそう。。
        end
    end

    # if文
    def para()
        unless get_token() == :para
            unget_token()
            return nil
        end
        result = [:para]
        unless token = get_token()
            raise Exception, "値がない"
        end
        result << token
    end
end

Sound.new