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
            scanner = StringScanner.new(@formula[i].chomp)
            @scan = scanner.scan(/(\d+|[\+\-\*\/()=]|[a-zA-Z]+)*/)
            @token = []
            @keywords = {
                '+' => :add,
                '-' => :sub,
                '*' => :mul,
                '/' => :div,
                '(' => :left_parn,
                ')' => :right_parn,
                'if' => :if,
                'keepon' => :for,
                'visu' => :print,
                'get' => :gets,
                '=' => :assignment
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
        # unget_token(token)
        p "expression"
        p result
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
        # unget_token(token)

        return result
    end

    def factor()
        token = get_token
        if token.is_a?(Numeric) # 数字だったら
            result = token
        elsif token == :left_parn #（ だったら
            result = expression()
            token = get_token # 閉じカッコを取り除く(使用しない)
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
        token = @scan[0]
        @scan = @scan[1..-1]
        # puts token
        # puts @scan

        case token
        when /[\+\-\*\/()=]/ # 符号の場合
            p token
            return @keywords[token]

        when /\d/ # 数字の場合
            @num = []
            @num << token.to_i
            loop do
                case @scan[0]
                when /\d/ # 数字だったら
                    token = @scan[0]
                    @scan = @scan[1..-1]
                    @num << token.to_i
                else
                    @num = @num.join
                    p @num
                    break
                end
            end
            return @num

        when /[a-zA-Z]/ # アルファベット（if, visu, keepon, get,..）の場合
            @alphabet = []
            @alphabet << token
            loop do
                case @scan[0]
                when /[a-zA-Z]/ # アルファベットだったら
                    token = @scan[0]
                    @scan = @scan[1..-1]
                    @alphabet << token
                else
                    @alphabet = @alphabet.join
                    p @alphabet
                    break
                end
            end
            return @alphabet
        end
    end

    # tokenを受け取り、ソースコードの先頭にそれを押し戻す。
    def unget_token(token)
        if token
            p "アンゲットトークン"
            p token
            result.unshift(token)
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
        # 代入文、if文、while文、print文、sentences()?
        token = get_token()
        if token == :left_parn #（ だったら
            result = sentences()
            token = get_token # 閉じカッコを取り除く(使用しない)
            if token != :right_parn then# ) なかったら
                raise Exception, "構文エラー" 
            end
        end

        # if文
        if token == :if then

        # for文
        elsif token == :keepon then

        # print文
        elsif token == :visu then

        # 入力
        elsif token == :get then

        # 代入文
        else
            result = get_token()
            if result == :assignment then
                # result = [result, [:variable, token], [:integer, "eval(expression)ができないunget_token.."]]
                # result = [result, [:variable, token], [:integer, eval(expression())]]
                result = [result, [:variable, token], [:integer, 1]]
                # eval(expression()もできないけど、eval(expression()で呼び出したいtokenがどこかで呼び出されちゃってる
            end
        end
        return result
    end


    
    # 入力
    def _get()
        return gets
    end

    # 出力
    def _visu(formula)
        puts formula
    end

    # for文
    def _keepon(formula, sentence)
        n = formula # n回繰り返す
        sentence # 繰り返したい式
        for i in 0..n.to_i do
            sentence
            # これじゃできなさそう。。
        end
    end

    # if文
    def _if(first, second)
        p "if文"
    end
end

Sound.new